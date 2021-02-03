#!/usr/bin/env ruby

require "tk_component"

class MyComponent < TkComponent::Base
  def render(p, parent_component)
    p.vframe(sticky: 'wens', padding: '4', x_flex: 1) do |f|
      f.label(text: "Name", sticky: 'w')
      f.hframe(sticky: 'ew', x_flex: 1) do |hf|
        @input = hf.entry(width: 8, sticky: 'we', x_flex: 1)
        hf.button(text: "Greet", on_click: :say_hello)
      end
      @res = f.text(width: 20, height: 4, sticky: 'ewns', x_flex: 1, y_flex: 1)
    end
  end

  def say_hello(e)
    @res.tk_item.value = "Hello #{@input.tk_item.value}"
  end
end

tk_root = TkComponent::Window.new(title: "Demo", root: true)
main_component = MyComponent.new
tk_root.place_root_component(main_component)

Tk.mainloop
