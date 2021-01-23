module TkComponent
  class BrowserComponent < TkComponent::Base

    attr_accessor :data_source
    attr_accessor :selected_path

    def initialize(options = {})
      super
      @data_source = options[:data_source]
      @selected_path = options[:selected_path] || []
      @paned = !!options[:paned]
    end

    def generate(parent_component, options = {})
      parse_component(parent_component, options) do |p|
        partial_path = []
        p.vframe(sticky: 'nsew', x_flex: 1, y_flex: 1) do |vf|
          command = @paned ? :hpaned : :hframe
          vf.send(command, sticky: 'nsew', x_flex: 1, y_flex: 1) do |f|
            ([ nil ] + selected_path).each.with_index do |item_at_level, idx|
              next_in_path = selected_path[idx]
              partial_path << item_at_level unless item_at_level.nil?
              items = data_source.items_for_path(partial_path)
              if items.present?
                f.tree(sticky: 'nsew', x_flex: 1, y_flex: 1,
                       scrollers: 'y', heading: data_source.title_for_path(partial_path)) do |t|
                  items.each do |item|
                    t.tree_node(at: 'end', text: item, selected: item == next_in_path)
                  end
                  t.on_select ->(e) { select_item(e.sender, idx) }
                end
              end
            end
          end
        end
      end
    end

    def select_item(sender, index)
      item = sender.native_item.selection&.first.text.to_s
      return if selected_path[index] == item
      selected_path[index] = item
      selected_path.slice!(index..-1) if index < selected_path.size - 1
      regenerate
    end
  end
end
