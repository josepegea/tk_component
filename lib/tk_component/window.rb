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
      h_weight = options[:h_weight] || 1
      v_weight = options[:v_weight] || 1
      TkGrid.columnconfigure tk_item.native_item, 0, weight: h_weight
      TkGrid.rowconfigure tk_item.native_item, 0, weight: v_weight
      add_child(component)
    end
  end
end
