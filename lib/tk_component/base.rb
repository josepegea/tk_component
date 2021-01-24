require 'tk'
require 'tkextlib/tile'

module TkComponent
  class Base

    attr_accessor :tk_item
    attr_accessor :parent
    attr_accessor :parent_node
    attr_accessor :children
    attr_accessor :node

    include BasicComponent

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

    def parse_node(parent_node, options = {})
      yield(parent_node)
      parent_node.prepare_option_events(self)
      parent_node.prepare_grid
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
      old_children = @children
      @children = []
      generate(parent)
      rebuild(old_node)
      @children.each do |c|
        c.generate(self)
        c.build(self)
      end
    end

    def regenerate_from_node(node, parent_node, options = {}, &block)
      old_children = @children.dup
      old_sub_nodes = parent_node.sub_nodes.dup
      # Remove this node and nodes after it
      to_remove = parent_node.sub_nodes.slice!(parent_node.sub_nodes.index(node)..-1)
      to_remove.each do |n|
        n.remove
      end
      parse_node(parent_node, options, &block)
      new_children = @children - old_children
      new_sub_nodes = parent_node.sub_nodes - old_sub_nodes
      new_sub_nodes.each do |n|
        # n.prepare_option_events(self)
        # n.prepare_grid
        n.build(parent_node, self)
      end
      new_children.each do |c|
        c.generate(self)
        c.build(self)
      end
    end

    def regenerate_after_node(node, parent_node, options = {}, &block)
      old_children = @children.dup
      old_sub_nodes = parent_node.sub_nodes.dup
      # Remove nodes after this one
      to_remove = parent_node.sub_nodes.slice!(parent_node.sub_nodes.index(node) + 1..-1)
      to_remove.each do |n|
        n.remove
      end
      parse_node(parent_node, options, &block)
      new_children = @children - old_children
      new_sub_nodes = parent_node.sub_nodes - old_sub_nodes
      new_sub_nodes.each do |n|
        # n.prepare_option_events(self)
        # n.prepare_grid
        n.build(parent_node, self)
      end
      new_children.each do |c|
        c.generate(self)
        c.build(self)
      end
    end

    def rebuild(old_node)
      build(parent)
    end

    # def rebuild_from_node(node, parent_node, new_children)
    #   parent_node.sub_nodes.slice(parent_node.sub_nodes.index(node)..-1).each do |n|
    #     n.build(parent_node, parent)
    #   end
    # end

    def name
      self.class.name
    end

    def emit(event_name)
      TkComponent::Builder::Event.emit(event_name, parent_node.native_item, self.object_id)
    end

    def component_did_build
    end

    def add_child(child)
      binding.pry if children.nil?
      children << child
    end
  end
end
