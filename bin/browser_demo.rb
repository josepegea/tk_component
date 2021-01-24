#!/usr/bin/env ruby

require "bundler/setup"
require "tk_component"
require "pry"

class DataSource
  @@shared_data_source = nil

  def self.shared
    @@shared_data_source ||= self.new
  end

  def items_for_path(path)
    path = [] if path.blank?
    path_str = File.join(ENV['HOME'], *path)
    return nil unless Dir.exist?(path_str)
    Dir.children(path_str)
  end

  def title_for_path(path, items)
    path.blank? ? ENV['HOME'] : path.last
  end
end
  
class DemoRoot < TkComponent::Base
  def generate(parent_component, options = {})
    parse_component(parent_component, options) do |p|
      p.vframe(sticky: 'wens', x_flex: 1, y_flex: 1) do |f|
        f.label(text: "Directory of #{DataSource.shared.title_for_path(nil, [])}")
        f.insert_component(TkComponent::BrowserComponent, self,
                           data_source: DataSource.shared,
                           paned: true,
                           sticky: 'nsew', x_flex: 1, y_flex: 1) do |bc|
          bc.on_event'PathChanged', ->(e) do
            puts "PathChanged: " + e.data_object.selected_path.to_s
          end
        end
      end
    end
  end
end

@tk_root = TkComponent::Window.new(title: "BrowserComponent Demo", root: true)
@main_component = DemoRoot.new
@tk_root.place_root_component(@main_component)

Tk.mainloop

