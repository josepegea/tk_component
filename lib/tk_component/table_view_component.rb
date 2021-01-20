module TkComponent
  class TableViewComponent < TkComponent::Base

    attr_accessor :data_source
    attr_accessor :columns
    attr_accessor :nested
    attr_accessor :lazy

    def initialize(options = {})
      super
      @data_source = options[:data_source]
      @columns = options[:columns]
      @nested = !!options[:nested]
      @lazy = !!options[:lazy]
      @to_load = {}
    end

    def generate(parent_component, options = {})
      @to_load = {}
      parse_component(parent_component, options) do |p|
        @tree = p.tree(sticky: 'nsew', h_weight: 1, v_weight: 1, scrollers: 'y',
                       column_defs: columns,
                       on_item_open: :item_open,
                       on_select: :item_selected
                      )
      end
    end

    def component_did_build
      items = data_source.items_for_path(nil)
      items.each do |item|
        add_item(@tree, item)
      end
    end

    def add_item(tree, item, parent_items = [], parent_item = nil)
      tree_item = tree.native_item.insert(parent_item || '', 'end', item_to_options(item))
      return unless nested && ((sub_path = parent_items + [ item ]) && data_source.has_sub_items?(sub_path))
      if lazy
        dummy_item = tree.native_item.insert(tree_item, 'end')
        @to_load[tree_item] = sub_path
      else
        sub_items = data_source.items_for_path(sub_path)
        sub_items.each do |sub_item|
          add_item(tree, sub_item, sub_path, tree_item)
        end
      end
    end

    def selected_item
      (tree_item = @tree.native_item.focus_item) && tree_item_to_item(tree_item)
    end

    def item_to_options(item)
      { text: item[text_key], values: item.slice(*values_keys).values }
    end

    def tree_item_to_item(tree_item)
      columns.map.with_index do |c, i|
        [c[:key],
         i == 0 ? tree_item.text : tree_item.get(c[:key])]
      end.to_h
    end

    def item_open(e)
      open_item = e.sender.native_item.focus_item
      return unless open_item.present?
      path = @to_load.delete(open_item)
      return unless path.present?
      @tree.native_item.delete(open_item.children)
      sub_items = data_source.items_for_path(path)
      sub_items.each do |sub_item|
        add_item(@tree, sub_item, path, open_item)
      end
    end

    def item_selected(e)
    end

    def text_key
      @text_key ||= columns.first[:key]
    end

    def values_keys
      @values_keys ||= columns[1..-1].map { |c| c[:key] }
    end
  end
end
