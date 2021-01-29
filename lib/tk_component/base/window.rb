module TkComponent
  class Window < Base
    def initialize(options = {})
      super
      @tk_item = Builder::TkItem.create(nil, :root, options)
    end

    def name
      "Window"
    end

    def place_root_component(component, options = {})
      component.parent = self
      component.generate(self)
      component.build(self)
      x_flex = options[:x_flex] || 1
      y_flex = options[:y_flex] || 1
      TkGrid.columnconfigure tk_item.native_item, 0, weight: x_flex
      TkGrid.rowconfigure tk_item.native_item, 0, weight: y_flex
      add_child(component)
    end
  end
end
