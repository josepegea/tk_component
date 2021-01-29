#!/usr/bin/env ruby

require "bundler/setup"
require "tk_component"
require "pry"

class ColorBlock < TkComponent::Base
  attr_accessor :color
  def initialize(options = {})
    super
    @color = options[:color] || 'white'
  end

  def render(p, parent_component)
    p.canvas(background: color, sticky: 'wens', x_flex: 1, y_flex: 1)
  end
end

class DemoRoot < TkComponent::Base
  COLORS = %w|red yellow green brown blue orange|
  ROWS = 10
  COLUMNS = 10

  def render(p, parent_component)
    p.frame(sticky: 'wens', x_flex: 1, y_flex: 1) do |f|
      f.row(sticky: 'wens', x_flex: 1, y_flex: 1) do |r|
        r.button(text: "Refresh", columnspan: COLUMNS, sticky: 'e') do |b|
          b.on_click ->(e) { regenerate }
        end
      end
      ROWS.times do
        f.row(sticky: 'wens', x_flex: 1, y_flex: 1) do |r|
          COLUMNS.times do
            r.insert_component(ColorBlock, self, color: random_color, sticky: 'nsew', x_flex: 1, y_flex: 1)
          end
        end
      end
    end
  end

  def random_color
    COLORS.sample
  end
end

@tk_root = TkComponent::Window.new(title: "Demo", root: true)
@main_component = DemoRoot.new
@tk_root.place_root_component(@main_component)

Tk.mainloop

