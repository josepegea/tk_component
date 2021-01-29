#!/usr/bin/env ruby

require "bundler/setup"
require "tk_component"
require "pry"

TABLE_COLS = %w|name size|

class DataSource
  @@shared_data_source = nil

  def self.shared
    @@shared_data_source ||= self.new
  end

  def items_for_path(path)
    path = [] if path.blank?
    path_str = File.join(ENV['HOME'], *file_segments_for(path))
    return nil unless Dir.exist?(path_str)
    Dir.children(path_str).map do |f|
      name = File.join(path_str, f)
      {
        name: f,
        size: File.exist?(name) && !File.directory?(name) && File.size(name) || ''
      }
    end
  end

  def has_sub_items?(path)
    path = [] if path.blank?
    path_str = File.join(ENV['HOME'], *file_segments_for(path))
    Dir.exist?(path_str)
  end

  private

  def file_segments_for(path)
    path.map { |p| p[:name] }
  end
end

class DemoRoot < TkComponent::Base
  def render(p, parent_component)
    p.vframe(sticky: 'wens', x_flex: 1, y_flex: 1) do |f|
      f.label(text: "Directory of #{ENV['HOME']}")
      f.insert_component(TkComponent::TableViewComponent, self,
                         data_source: DataSource.shared,
                         columns: [
                           { key: :name, text: 'Name' },
                           { key: :size, text: 'Size' }
                         ],
                         nested: true,
                         lazy: true,
                         sticky: 'nsew', x_flex: 1, y_flex: 1)
    end
  end
end

@tk_root = TkComponent::Window.new(title: "TableView Demo", root: true)
@main_component = DemoRoot.new
@tk_root.place_root_component(@main_component)

Tk.mainloop

