require_relative 'browser_column_component'

module TkComponent
  class RBrowserComponent < TkComponent::Base

    attr_accessor :data_source
    attr_accessor :selected_path
    attr_accessor :paned
    attr_accessor :max_columns

    def initialize(options = {})
      super
      @data_source = options[:data_source]
      @selected_path = options[:selected_path] || []
      @paned = !!options[:paned]
      @max_columns = options[:max_columns]
    end

    def generate(parent_component, options = {})
      parse_component(parent_component, options) do |p|
        p.insert_component(TkComponent::BrowserColumnComponent, self,
                           browser: self,
                           column_index: 0,
                           sticky: 'nsew', x_flex: 1, y_flex: 1) do |bc|
          bc.on_event 'ItemSelected', ->(e) do
            puts "ItemSelected"
            emit('PathChanged')
          end
        end
      end
    end
  end
end
