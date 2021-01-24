module TkComponent
  class BrowserComponent < TkComponent::Base

    attr_accessor :data_source
    attr_accessor :selected_path

    def initialize(options = {})
      super
      @data_source = options[:data_source]
      @selected_path = options[:selected_path] || []
      @paned = !!options[:paned]
      @trees_container = nil
      @trees = []
    end

    def generate(parent_component, options = {})
      parse_component(parent_component, options) do |p|
        partial_path = []
        p.vframe(sticky: 'nsew', x_flex: 1, y_flex: 1) do |vf|
          command = @paned ? :hpaned : :hframe
          @trees_container = vf.send(command, sticky: 'nsew', x_flex: 1, y_flex: 1) do |f|
            generate_from_level(f, 0)
          end
        end
      end
    end

    def generate_from_level(container, start_index)
      (start_index..selected_path.size).each do |idx|
        next_in_path = selected_path[idx]
        partial_path = selected_path.slice(0, idx)
        items = data_source.items_for_path(partial_path)
        title = items.nil? ? '' : data_source.title_for_path(partial_path, items)
        @trees << container.tree(sticky: 'nsew', x_flex: 1, y_flex: 1,
                                 scrollers: 'y', heading: title) do |t|
          items&.each do |item|
            t.tree_node(at: 'end', text: item, selected: item == next_in_path)
          end
          t.on_select ->(e) { select_item(e.sender, idx) }
        end
      end
    end

    def select_item(sender, index)
      item = sender.native_item.selection&.first.text.to_s
      return if selected_path[index] == item
      selected_path[index] = item
      selected_path.slice!(index + 1..-1) if index < selected_path.size - 1
      @trees.slice!(index + 1..-1)
      regenerate_after_node(@trees[index], @trees_container) do |container|
        generate_from_level(container, index + 1)
      end
      emit('PathChanged')
    end
  end
end
