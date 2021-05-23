module TkComponent
  module Builder

    TK_CMDS = %w(label entry button radio_set radio_button canvas text scale group tree tree_node hscroll_bar vscroll_bar hpaned vpaned).to_set.freeze
    LAYOUT_CMDS = %w(frame hframe vframe row cell).to_set.freeze
    EVENT_CMDS = %w(on_change on_mouse_down on_mouse_up on_mouse_drag on_mouse_enter on_mouse_leave on_mouse_wheel on_click on_select on_item_open on_event).to_set.freeze
    TOKENS = (TK_CMDS + LAYOUT_CMDS + EVENT_CMDS).freeze

    LAYOUT_OPTIONS = %i(column row rowspan columnspan sticky x_flex y_flex)

    class Node
      attr_accessor :name
      attr_accessor :options
      attr_accessor :sub_nodes
      attr_accessor :grid
      attr_accessor :weights
      attr_accessor :grid_map
      attr_accessor :event_handlers
      attr_accessor :tk_item

      delegate :value, to: :tk_item
      delegate :"value=", to: :tk_item
      delegate :update_value, to: :tk_item
      delegate :i_value, to: :tk_item
      delegate :f_value, to: :tk_item
      delegate :s_value, to: :tk_item
      delegate :from, to: :tk_item
      delegate :to, to: :tk_item
      delegate :native_item, to: :tk_item

      def initialize(name, options = {})
        @name = name
        @options = options.with_indifferent_access
        @sub_nodes = []
        @grid = {}.with_indifferent_access
        @weights = {}.with_indifferent_access
        @grid_map = GridMap.new
        @event_handlers = []
        @tk_item = nil
      end

      def short(level = 0)
        @sub_nodes.each do |n|
          n.short(level + 4)
        end
        nil
      end

      def insert_component(component_class, parent_component, options = {}, &block)
        layout_options = options.slice(*LAYOUT_OPTIONS)
        c_node = node_from_command(:frame, layout_options, &block)
        comp = component_class.new(options.merge(parent: parent_component, parent_node: c_node))
        comp.generate(parent_component)
        parent_component.add_child(comp)
        comp
      end

      def add_event_handler(name, lambda, options = {})
        event_handlers << EventHandler.new(name, lambda, options)
      end

      def build(parent_node, parent_component)
        parent_item = parent_node.present? ? parent_node.tk_item : parent_component.tk_item
        self.tk_item = TkItem.create(parent_item, name, options, grid, event_handlers)
        parent_component.tk_item = self.tk_item if parent_component.tk_item.nil?
        sub_nodes.each do |n|
          n.build(self, parent_component)
        end
        apply_grid
        built
      end

      def apply_grid
        self.tk_item.apply_internal_grid(grid_map)
      end

      def built
        self.tk_item.built
      end

      def rebuilt
      end

      def remove
        self.tk_item.remove
      end

      def prepare_option_events(component)
        option_events = options.extract!(*EVENT_CMDS)
        option_events.each do |k, v|
          event_proc = v.is_a?(Proc) ? v : proc { |e| component.public_send(v, e) }
          node_from_command(k, event_proc)
        end
        sub_nodes.each { |n| n.prepare_option_events(component) }
      end

      def prepare_grid
        self.grid_map = GridMap.new
        return unless self.sub_nodes.any?
        current_row = -1
        current_col = -1
        final_sub_nodes = []
        going_down = going_down?
        while (n = sub_nodes.shift) do
          if n.row?
            current_row += 1
            current_col = 0
            sub_nodes.unshift(*n.sub_nodes)
          else
            # Set the initial row and cols if no row was specified
            current_row = 0 if current_row < 0
            current_col = 0 if current_col < 0
            current_row, current_col = grid_map.get_next_cell(current_row, current_col, going_down)
            binding.pry if n.options.nil?
            n.grid = {}.with_indifferent_access if n.grid.nil?
            n.grid.merge!(n.options.extract!(:column, :row, :rowspan, :columnspan, :sticky))
            n.grid.merge!(column: current_col, row: current_row)
            rowspan = n.grid[:rowspan] || 1
            columnspan = n.grid[:columnspan] || 1
            grid_map.fill(current_row, current_col, rowspan, columnspan, true)
            n.weights = {}.with_indifferent_access if n.weights.nil?
            n.weights.merge!(n.options.extract!(:x_flex, :y_flex))
            grid_map.set_weights(current_row, current_col, n.weights)
            n.prepare_grid
            final_sub_nodes << n
          end
        end
        self.sub_nodes = final_sub_nodes
      end

      def method_missing(method_name, *args, &block)
        if method_name.to_s.match(/(.*)\?/)
          return name.to_s == $1
        end
        if TOKENS.include?(method_name.to_s)
          return node_from_command(method_name, *args, &block)
        end
        super
      end

      def node_from_command(method_name, *args, &block)
        if method_name.to_s == 'on_event'
          args[0] = "<#{args[0]}>"
          add_event_handler(*args)
        elsif method_name.to_s.match(/^on_(.*)/)
          add_event_handler($1, *args)
        else
          builder = self.class.new(method_name, *args)
          yield(builder) if block_given?
          add_node(builder)
          return builder
        end
      end

      def going_down?
        vframe?
      end

      def add_node(node)
        sub_nodes << node
      end
    end
  end
end
