#!/usr/bin/env ruby

require "bundler/setup"
require "tk_component"
require "pry"

class ColorBlock < TkComponent::Base
  def generate(parent_component, options = {})
    parse_component(parent_component, options) do |p|
      p.canvas(background: options[:color], sticky: 'wens', h_weight: 1, v_weight: 1)
    end
  end
end

class DemoRoot < TkComponent::Base
  COLORS = %w|red yellow green brown blue orange|
  ROWS = 10
  COLUMNS = 10
  def generate(parent_component, options = {})
    parse_component(parent_component, options) do |p|
      p.frame(sticky: 'wens', h_weight: 1, v_weight: 1) do |f|
        f.row(sticky: 'wens', h_weight: 1, v_weight: 1) do |r|
          r.button(text: "Refresh", columnspan: COLUMNS, sticky: 'e') do |b|
            b.on_click ->(e) { regenerate }
          end
        end
        ROWS.times do
          f.row(sticky: 'wens', h_weight: 1, v_weight: 1) do |r|
            COLUMNS.times do
              r.insert_component(ColorBlock, self, color: random_color, sticky: 'nsew', h_weight: 1, v_weight: 1)
            end
          end
        end
      end
    end
  end

  def random_color
    COLORS.sample
  end
end

@tk_root = TkComponent::Window.new(title: "Demo")
@main_component = DemoRoot.new
@tk_root.place_root_component(@main_component)

Tk.mainloop

