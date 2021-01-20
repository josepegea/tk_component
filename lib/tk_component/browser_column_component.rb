module TkComponent
  class BrowserColumnComponent < TkComponent::Base

    attr_accessor :browser
    attr_accessor :column_index

    def initialize(options = {})
      super
      @browser = options[:browser]
      @column_index = options[:column_index] || 0
    end

    def generate(parent_component, options = {})
      parse_component(parent_component, options) do |p|
        if @column_index <= @browser.selected_path.size
          current_item = @browser.selected_path[@column_index]
          path_so_far = @browser.selected_path.slice(0, @column_index)
          items = @browser.data_source.items_for_path(path_so_far)
          items ||= []
        else
          items = []
          current_item = nil
        end
        command = @browser.paned ? :hpaned : :hframe
        puts "Generating #{@column_index} - #{current_item}"
        p.send(command, sticky: 'nsew', h_weight: 1, v_weight: 1) do |f|
          @tree = f.tree(sticky: 'nsew', h_weight: 1, v_weight: 1,
                         on_select: :select_item,
                         scrollers: 'y', heading: @browser.data_source.title_for_path(path_so_far, items)) do |t|
            items.each do |item|
              t.tree_node(at: 'end',
                          text: item,
                          selected: item == current_item)
            end
          end
          if (@browser.max_columns.blank? || @browser.max_columns > @column_index + 1) &&
             (@column_index < @browser.selected_path.size || items.present?)               
            f.hframe(sticky: 'nsew', h_weight: 1, v_weight: 1) do |hf|
              @next_column = hf.insert_component(TkComponent::BrowserColumnComponent, self,
                                                 browser: @browser,
                                                 column_index: @column_index + 1,
                                                 sticky: 'nsew', h_weight: 1, v_weight: 1) do |bc|
                bc.on_event 'ItemSelected', ->(e) do
                  puts "ItemSelected"
                  emit('ItemSelected')
                end
              end
            end
          end
        end
      end
    end

    def component_did_build
      show_current_selection
    end

    def show_current_selection
      @tree.tk_item.scroll_to_selection
    end

    def select_item(e)
      item = e.sender.native_item.selection&.first.text.to_s
      return if @browser.selected_path[@column_index] == item
      @browser.selected_path[@column_index] = item
      @browser.selected_path.slice!(@column_index + 1..-1) if @column_index < @browser.selected_path.size - 1
      puts "New selected path: #{@browser.selected_path}"
      @next_column&.regenerate
      emit('ItemSelected')
    end
  end
end
