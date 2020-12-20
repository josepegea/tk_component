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
        tk_class = TK_CLASSES[name.to_sym]
        raise "Don't know how to create #{name}" unless tk_class
        @native_item = tk_class.new(parent_item.native_item)
        apply_options(options)
        set_grid(grid)
        set_event_handlers(event_handlers)
      end

      def apply_options(options)
        options.each do |k,v|
          apply_option(k, v)
        end
      end

      def apply_option(option, value)
        self.native_item.public_send(option, value)
      end

      def set_grid(grid)
        self.native_item.grid(grid)
      end

      def apply_internal_grid(grid_map)
        puts(grid_map)
        grid_map.column_indexes.each { |c| TkGrid.columnconfigure(self.native_item, c, weight: grid_map.column_weight(c)) }
        grid_map.row_indexes.each { |r| TkGrid.rowconfigure(self.native_item, r, weight: grid_map.row_weight(r)) }
        # grid_map.column_indexes.each { |c| TkGrid.columnconfigure(self.native_item, c, weight: 1) }
        # grid_map.row_indexes.each { |r| TkGrid.rowconfigure(self.native_item, r, weight: 1) }
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
    end

    module ValueTyping
      def apply_option(option, v)
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
        @tk_variable = TkVariable.new
        super
        self.native_item.public_send(variable_name, @tk_variable)
      end

      def variable_name
        :variable
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

    class TkText < TkItem
      include ValueTyping

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

      def append_text(text)
        native_item.insert('end', text)
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
      @column_defs = []

      def apply_options(options)
        super
        return unless @column_defs.present?
        cols = @column_defs.map { |c| c[:key] }
        native_item.columns(cols.join(' '))
        @column_defs.each do |cd|
          column_conf = cd.slice(:width, :anchor)
          native_item.column_configure(cd['key'], column_conf) unless column_conf.empty?
          heading_conf = cd.slice(:text)
          native_item.heading_configure(cd['key'], heading_conf) unless heading_conf.empty?
        end
      end

      def apply_option(option, v)
        super unless option.to_sym == :column_defs
        @column_defs = v
      end

      def set_event_handler(event_handler)
        case event_handler.name
        when :select
          Event.bind_event('<TreeviewSelect>', self, event_handler.options, event_handler.lambda)
        else
          super
        end
      end
    end

    class TkTreeNode < TkItem
      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        parent_node = options.delete(:parent) || ''
        parent_native_item = (parent_node == '' ? '' : parent_node.native_item)
        at = options.delete(:at)
        selected = options.delete(:selected)
        @native_item = parent_item.native_item.insert(parent_native_item, at, options)
        parent_item.native_item.selection_add(@native_item) if selected
        set_event_handlers(event_handlers)
      end
    end

    class TkWindow < TkItem
      def initialize(parent_item, name, options = {}, grid = {}, event_handlers = [])
        @native_item = TkToplevel.new { title options[:title] }
        apply_options(options)
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
      canvas: Tk::Canvas,
      text: ::TkText,
      scale: Tk::Tile::Scale,
      group: Tk::Tile::LabelFrame,
      tree: Tk::Tile::Treeview
    }

    ITEM_CLASSES = {
      root: TkComponent::Builder::TkWindow,
      frame: TkComponent::Builder::TkItem,
      hframe: TkComponent::Builder::TkItem,
      vframe: TkComponent::Builder::TkItem,
      label: TkComponent::Builder::TkItem,
      entry: TkComponent::Builder::TkEntry,
      button: TkComponent::Builder::TkItem,
      canvas: TkComponent::Builder::TkItem,
      text: TkComponent::Builder::TkText,
      scale: TkComponent::Builder::TkScale,
      group: TkComponent::Builder::TkItem,
      tree: TkComponent::Builder::TkTree,
      tree_node: TkComponent::Builder::TkTreeNode
    }
  end
end
