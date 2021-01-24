module TkComponent
  module Builder
    class TkItem

      attr_accessor :native_item

      def self.create(parent_item, name, options = {}, grid = {}, event_handlers = [])
        item_class = ITEM_CLASSES[name.to_sym]
        raise "Don't know how to create #{name}" unless item_class
        item_class.new(parent_item, name, options, grid, event_handlers)
      end

      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        @native_item = create_native_item(parent_item.native_item, name, options, grid, event_handlers)
        apply_options(options)
        set_grid(grid)
        set_event_handlers(event_handlers)
      end

      def create_native_item(parent_native_item, name, options = {}, grid = {}, event_handlers = [])
        native_item_class(parent_native_item, name, options, grid, event_handlers).new(parent_native_item)
      end

      def native_item_class(parent_native_item, name, options = {}, grid = {}, event_handlers = [])
        tk_class = TK_CLASSES[name.to_sym]
        raise "Don't know how to create #{name}" unless tk_class.present?
        return tk_class
      end

      def remove
        @native_item.destroy
      end

      def apply_options(options, to_item = self.native_item)
        options.each do |k,v|
          apply_option(k, v, to_item)
        end
      end

      def apply_option(option, value, to_item = self.native_item)
        to_item.public_send(option, value)
      end

      def set_grid(grid, to_item = self.native_item)
        to_item.grid(grid)
      end

      def apply_internal_grid(grid_map)
        grid_map.column_indexes.each { |c| TkGrid.columnconfigure(self.native_item, c, weight: grid_map.column_weight(c)) }
        grid_map.row_indexes.each { |r| TkGrid.rowconfigure(self.native_item, r, weight: grid_map.row_weight(r)) }
      end

      def set_event_handlers(event_handlers)
        event_handlers.each { |eh| set_event_handler(eh) }
      end

      def set_event_handler(event_handler)
        case event_handler.name
        when :click
          Event.bind_command(event_handler.name, self, event_handler.options, event_handler.lambda)
        when :change
          Event.bind_variable(event_handler.name, self, event_handler.options, event_handler.lambda)
        else
          Event.bind_event(event_handler.name, self, event_handler.options, event_handler.lambda)
        end
      end

      def built(parent_item)
      end

      def focus
        self.native_item.focus
      end
    end

    module ValueTyping
      def apply_option(option, v, to_item = self.native_item)
        case option.to_sym
        when :value
          self.value = v
        else
          super
        end
      end

      def update_value(v)
        self.value = v if value.to_s != v.to_s
      end

      def i_value
        value.to_i
      end

      def f_value
        value.to_f
      end

      def s_value
        value.to_s
      end
    end

    class TkItemWithVariable < TkItem
      include ValueTyping

      attr_accessor :tk_variable

      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        create_variable
        super
        apply_variable
      end

      def variable_name
        :variable
      end

      def apply_variable
        self.native_item&.public_send(variable_name, @tk_variable)
      end

      def create_variable
        @tk_variable = TkVariable.new
      end

      delegate :value, to: :tk_variable
      delegate :"value=", to: :tk_variable
    end

    class TkEntry < TkItemWithVariable
      def variable_name
        :textvariable
      end
    end

    class TkScale < TkItemWithVariable
      def variable_name
        :variable
      end

      delegate :from, to: :native_item
      delegate :to, to: :native_item

      def set_event_handler(event_handler)
        case event_handler.name
        when :change
          Event.bind_command(event_handler.name, self, event_handler.options, event_handler.lambda)
        else
          super
        end
      end
    end

    class TkRadioSet < TkItemWithVariable
      # The variable for the radio set is only to be used by radio buttons inside it
      # Thus, we don't try to link it to the actual item
      def apply_variable
      end
    end

    class TkRadioButton < TkItemWithVariable
      # We need to use the tk_variable created by the parent_item
      # So we set it here and skip creation below
      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        @tk_variable = parent_item.tk_variable
        super
      end

      def create_variable
      end

      # It is unfortunate that native TK radio buttons use 'value' to
      # spedify the value for each of them, colliding with the 'value'
      # methods for our items with variables. Thus, we need to
      # override the setting of the 'value' option to revert it to the
      # default functionality
      def apply_option(option, v, to_item = self.native_item)
        case option.to_sym
        when :value
          to_item.public_send(option, v)
        else
          super
        end
      end
    end

    module Scrollable
      ROOT_FRAME_OPTIONS = %i|width height relief borderwidth padx pady padding| + TkComponent::Builder::LAYOUT_OPTIONS

      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        return super unless (s_options = options.delete(:scrollers)) && s_options.present? && s_options != 'none'
        frame_item = TK_CLASSES[:frame].new(parent_item.native_item) # Containing frame
        real_native_item = create_native_item(frame_item, name, options, grid, event_handlers)
        f_options = options.extract!(*ROOT_FRAME_OPTIONS)
        apply_options(f_options, frame_item) # Apply the applicable options to the enclosing frame
        @native_item = real_native_item
        apply_options(options, real_native_item)
        set_grid(grid, frame_item)
        real_native_item.grid( :column => 0, :row => 0, :sticky => 'nwes')
        if s_options.include?('x')
          h_scrollbar = TK_CLASSES[:hscroll_bar].new(frame_item)
          h_scrollbar.orient('horizontal')
          h_scrollbar.command proc { |*args| real_native_item.xview(*args) }
          real_native_item['xscrollcommand'] = proc { |*args| h_scrollbar.set(*args) }
          h_scrollbar.grid( :column => 0, :row => 1, :sticky => 'wes')
        end
        if s_options.include?('y')
          v_scrollbar =  TK_CLASSES[:vscroll_bar].new(frame_item)
          v_scrollbar.orient('vertical')
          v_scrollbar.command proc { |*args| real_native_item.yview(*args) }
          real_native_item['yscrollcommand'] = proc { |*args| v_scrollbar.set(*args) }
          v_scrollbar.grid( :column => 1, :row => 0, :sticky => 'nse')
        end
        TkGrid.columnconfigure(frame_item, 0, :weight => 1)
        TkGrid.columnconfigure(frame_item, 1, :weight => 0) if v_scrollbar.present?
        TkGrid.rowconfigure(frame_item, 0, :weight => 1)
        TkGrid.rowconfigure(frame_item, 1, :weight => 0) if h_scrollbar.present?
        @native_item = real_native_item
        set_event_handlers(event_handlers)
      end

      # We need to remove the parent native item, as it's the container we put in place initially
      def remove
        @native_item.winfo_parent.destroy
      end
    end

    class TkText < TkItem
      include ValueTyping
      include Scrollable

      def value
        native_item.get('1.0', 'end')
      end

      def value=(text)
        native_item.replace('1.0', 'end', text)
      end

      def selected_text
        ranges = native_item.tag_ranges('sel')
        return nil if ranges.empty?
        native_item.get(ranges.first.first, ranges.first.last)
      end

      def current_line
        native_item.get('insert linestart', 'insert lineend')
      end

      def append_text(text)
        native_item.insert('end', text)
      end

      def select_range(from, to)
        native_item.tag_add('sel', from, to)
      end

      def set_event_handler(event_handler)
        case event_handler.name
        when :change
          pre_lambda = ->(e) do
            # Prevent the event if the text wasn't really modified
            # This is because setting "modified = false" triggers
            # the modification event itself, which makes not much sense.
            e.sender.is_a?(self.class) && !e.sender.native_item.modified?
          end
          post_lambda = ->(e) do
            if e.sender.is_a?(self.class)
              e.sender.native_item.modified = false
            end
          end
          Event.bind_event('<Modified>', self, event_handler.options, event_handler.lambda, pre_lambda, post_lambda)
        else
          super
        end
      end
    end

    class TkTree < TkItem
      include Scrollable
      @column_defs = []

      def apply_options(options, to_item = self.native_item)
        super
        return unless @column_defs.present?
        cols = @column_defs.map { |c| c[:key] }
        to_item.columns(cols[1..-1].join(' ')) unless cols == ['#0']
        @column_defs.each.with_index do |cd, idx|
          key = idx == 0 ? '#0' : cd[:key]
          column_conf = cd.slice(:width, :anchor)
          to_item.column_configure(key, column_conf) unless column_conf.empty?
          heading_conf = cd.slice(:text)
          to_item.heading_configure(key, heading_conf) unless heading_conf.empty?
        end
      end

      def apply_option(option, v, to_item = self.native_item)
        case option.to_sym
        when :column_defs
          @column_defs = v
        when :heading
          @column_defs = [ { key: '#0', text: v } ]
        else
          super
        end
      end

      def set_event_handler(event_handler)
        case event_handler.name
        when :select
          Event.bind_event('<TreeviewSelect>', self, event_handler.options, event_handler.lambda)
        when :item_open
          Event.bind_event('<TreeviewOpen>', self, event_handler.options, event_handler.lambda)
        else
          super
        end
      end

      def scroll_to_selection
        scroll_to_item(@native_item.selection.first)
      end

      # Right now it only works well for non-nested trees
      def scroll_to_item(tree_item)
        return unless tree_item.present?
        items = @native_item.children('')
        rel_pos = items.index(tree_item).to_f / items.size.to_f
        @native_item.after(200) { @native_item.yview_moveto(rel_pos) }
      end
    end

    class TkTreeNode < TkItem
      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        item_options = options.dup
        parent_node = item_options.delete(:parent) || ''
        parent_native_item = (parent_node == '' ? '' : parent_node.native_item)
        at = item_options.delete(:at)
        selected = item_options.delete(:selected)
        @native_item = parent_item.native_item.insert(parent_native_item, at, item_options)
        parent_item.native_item.selection_add(@native_item) if selected
        set_event_handlers(event_handlers)
      end
    end

    class ScrollBar < TkItem
      def apply_option(option, v, to_item = self.native_item)
        case option.to_sym
        when :linked_to
          @linked_to = v
        else
          super
        end
      end

      def set_event_handler(event_handler)
        case event_handler.name
        when :change
          Event.Event.bind_command(event_handler.name, self, event_handler.options, event_handler.lambda)
        else
          super
        end
      end

      def apply_options(options, to_item = self.native_item)
        options.merge!(orient: orient)
        super
      end

      def set_event_handlers(event_handlers)
        bind_linked_to
        super
      end

      def bind_linked_to
        return unless @linked_to.present?
        items = @linked_to.is_a?(Array) ? @linked_to.map(&:native_item) : [ @linked_to.native_item ]
        self.native_item.command proc { |*args|
          items.each do |item|
            item.send(scroll_command, *args)
          end
        }
        items.each do |item|
          item.send(linked_scroll_command, proc { |*args| self.native_item.send(linked_scroll_event, *args) })
        end
      end

      def orient
        raise "#{self.class.to_s} shouldn't be instantiated directly. Use 'H' or 'V' subclasses"
      end

      def scroll_command
        raise "#{self.class.to_s} shouldn't be instantiated directly. Use 'H' or 'V' subclasses"
      end

      def linked_scroll_command
        raise "#{self.class.to_s} shouldn't be instantiated directly. Use 'H' or 'V' subclasses"
      end

      def linked_scroll_event
        raise "#{self.class.to_s} shouldn't be instantiated directly. Use 'H' or 'V' subclasses"
      end
    end

    class HScrollbar < ScrollBar
      def orient
        'horizontal'
      end

      def scroll_command
        :xview
      end

      def linked_scroll_command
        :xscrollcommand
      end

      def linked_scroll_event
        :set
      end
    end

    class VScrollbar < ScrollBar
      def orient
        'vertical'
      end

      def scroll_command
        :yview
      end

      def linked_scroll_command
        :yscrollcommand
      end

      def linked_scroll_event
        :set
      end
    end

    class PanedWindow < TkItem
      def create_native_item(parent_native_item, name, options = {}, grid = {}, event_handlers = [])
        native_item_class(parent_native_item, name, options, grid, event_handlers).new(parent_native_item, orient: orient)
      end

      def built(parent_item)
        # We need to add all children items to the panned window
        self.native_item.winfo_children.each do |child|
          self.native_item.add(child, weight: 1)
        end
      end

      def orient
        raise "#{self.class.to_s} shouldn't be instantiated directly. Use 'H' or 'V' subclasses"
      end
    end

    class HPanedWindow < PanedWindow
      def orient
        'horizontal'
      end
    end

    class VPanedWindow < PanedWindow
      def orient
        'vertical'
      end
    end

    class TkWindow < TkItem
      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        if (options.delete(:root))
          @native_item = TkRoot.new { title options[:title] }
        else
          @native_item = TkToplevel.new { title options[:title] }
        end
        apply_options(options)
      end

      def focus
        self.native_item.set_focus
      end
    end

    TK_CLASSES = {
      root: TkRoot,
      frame: Tk::Tile::Frame,
      hframe: Tk::Tile::Frame,
      vframe: Tk::Tile::Frame,
      label: Tk::Tile::Label,
      entry: Tk::Tile::Entry,
      button: Tk::Tile::Button,
      radio_set: Tk::Tile::Frame,
      radio_button: Tk::Tile::RadioButton,
      canvas: Tk::Canvas,
      text: ::TkText,
      scale: Tk::Tile::Scale,
      group: Tk::Tile::LabelFrame,
      tree: Tk::Tile::Treeview,
      hscroll_bar: Tk::Tile::Scrollbar,
      vscroll_bar: Tk::Tile::Scrollbar,
      hpaned: Tk::Tile::Paned,
      vpaned: Tk::Tile::Paned
    }

    ITEM_CLASSES = {
      root: TkComponent::Builder::TkWindow,
      frame: TkComponent::Builder::TkItem,
      hframe: TkComponent::Builder::TkItem,
      vframe: TkComponent::Builder::TkItem,
      label: TkComponent::Builder::TkItem,
      entry: TkComponent::Builder::TkEntry,
      button: TkComponent::Builder::TkItem,
      radio_set: TkComponent::Builder::TkRadioSet,
      radio_button: TkComponent::Builder::TkRadioButton,
      canvas: TkComponent::Builder::TkItem,
      text: TkComponent::Builder::TkText,
      scale: TkComponent::Builder::TkScale,
      group: TkComponent::Builder::TkItem,
      tree: TkComponent::Builder::TkTree,
      tree_node: TkComponent::Builder::TkTreeNode,
      hscroll_bar: TkComponent::Builder::HScrollbar,
      vscroll_bar: TkComponent::Builder::VScrollbar,
      hpaned: TkComponent::Builder::HPanedWindow,
      vpaned: TkComponent::Builder::VPanedWindow

    }
  end
end
