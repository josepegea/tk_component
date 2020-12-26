require 'tk'
require 'tkextlib/tile'

module TkComponent
  class Base

    attr_accessor :tk_item
    attr_accessor :parent
    attr_accessor :parent_node
    attr_accessor :children
    attr_accessor :node

    def initialize(options = {})
      @parent = options[:parent]
      @parent_node = options[:parent_node]
      @children = []
    end

    def parse_component(parent_component, options = {})
      raise "You need to provide a block" unless block_given?
      @node = Builder::Node.new(:top, options)
      yield(@node)
      binding.pry if @node.sub_nodes.size != 1
      raise "Components need to have a single root node" unless @node.sub_nodes.size == 1
      @node.prepare_option_events(self)
      @node.prepare_grid
      @node = @node.sub_nodes.first # Get rid of the dummy top node
    end

    def build(parent_component)
      @node.build(@parent_node, parent_component)
      component_did_build
      children.each do |c|
        c.build(self)
        TkGrid.columnconfigure c.parent_node.tk_item.native_item, 0, weight: 1
        TkGrid.rowconfigure c.parent_node.tk_item.native_item, 0, weight: 1
        TkGrid.columnconfigure c.node.tk_item.native_item, 0, weight: 1
        TkGrid.rowconfigure c.node.tk_item.native_item, 0, weight: 1
      end
    end

    def regenerate
      old_node = @node
      generate(parent)
      rebuild(old_node)
      children.each do |c|
        c.regenerate
      end
    end

    def rebuild(old_node)
      build(parent)
    end

    def name
      self.class.name
    end

    def emit(event_name)
      TkComponent::Builder::Event.emit('ParamChanged', parent_node.native_item, self.object_id)
    end

    def component_did_build
    end

    def add_child(child)
      binding.pry if children.nil?
      children << child
    end
  end
end
