# frozen_string_literal: true

module RubyLsp
  module Hanami
    # top level comment
    class KeyForest
      attr_reader :trees, :tree_indices

      def initialize
        @trees = []
        @tree_indices = {}
      end

      def key?(key:)
        !find_entry(key: key).nil?
      end

      def add_entry(key:, entry:)
        # provide a way to pass a traditional key (e.g.: 'how.we.encounter.it'), but allow for
        # the caller to optimize and pass an array to prevent needless splitting
        key_parts = key.is_a?(String) ? key.split(".") : key
        root = key_parts[0]

        # check to see if we've seen this root
        tree_index = @tree_indices[root]

        if !tree_index.nil?
          # tree exists
          node = @trees[tree_index]
          insert(node: node, key_parts: key_parts, entry: entry)
        else
          # add a tree
          create_tree(key_parts: key_parts, entry: entry)
        end
      end

      def entry(key:)
        find_entry(key: key)
      end

      # find and return what the next part of a container key could be
      def completion_options(key:)
        key_parts = key.is_a?(String) ? key.split(".") : key
        root = key_parts[0]
        tree_index = @tree_indices[root]

        if tree_index.nil?
          # give suggestions of potential first chunks
          t = []
          @tree_indices.keys.each do |key|
            t << key if key.include?(root)
          end
          return t
        end

        node = @trees[tree_index]
        options = []

        key_parts.each_with_index do |part, idx|
          if part == key_parts.last && node.name == part
            options = node.children.map(&:name)
            break
          end

          next if idx.zero?

          node.children.each do |child|
            if child.name == part
              node = child
              break
            end
          end

          if part == key_parts.last && node.name == part
            options = node.children.map(&:name)
            break
          end
        end

        options
      end

      # here for debugging
      def print_trees
        @trees.each_with_index do |root_node, idx|
          p "printing tree with index: #{idx}\n"
          print_subtree(node: root_node)
        end
      end

      def print_subtree(node:)
        print "node: #{node.name}\n"
        print "children: #{node.children}\n"

        if node.children.empty?
          print "entry: #{node.entry}"
          return
        end

        node.children.each do |child|
          print_subtree(node: child)
        end
      end

      private

      def insert(node:, key_parts:, entry:)
        key_parts.each_with_index do |part, idx|
          if part == key_parts.last && node.name == part
            node.add_leaf(entry: entry)
            break
          end

          next if idx.zero?

          found = false

          node.children.each do |child|
            next unless child.name == part

            insert(node: child, key_parts: key_parts[idx..], entry: entry)
            found = true
            break
          end

          break if found

          new_node = Node.new(name: part)
          node.add_child(node: new_node)

          if part == key_parts.last
            new_node.add_leaf(entry: entry)
            break
          end

          insert(node: new_node, key_parts: key_parts[idx..], entry: entry)
        end
      end

      def create_tree(key_parts:, entry:)
        root = key_parts[0]
        root_node = Node.new(name: root)
        previous_node = root_node

        key_parts.each_with_index do |part, idx|
          next if idx.zero?

          node = Node.new(name: part)

          previous_node.add_child(node: node)
          previous_node = node
        end

        previous_node.add_leaf(entry: entry)
        @tree_indices[root] = @trees.length
        @trees << root_node
      end

      def find_entry(key:)
        key_parts = key.is_a?(String) ? key.split(".") : key
        root = key_parts[0]
        tree_index = @tree_indices[root]

        return nil if tree_index.nil? # TODO: better to be a custom error?

        result = nil
        node = @trees[tree_index]

        key_parts.each_with_index do |part, idx|
          next if idx.zero? # root

          matched_child = node.children.index { |child| child.name == part }
          break if matched_child.nil?

          node = node.children[matched_child]

          if !node.entry.nil? && part == key_parts.last
            result = node.entry
            break
          end
        end

        result
      end
    end

    # top level comment
    class Node
      attr_reader :name, :children, :entry

      def initialize(name:)
        @name = name
        @children = []
        @entry = nil
      end

      def add_child(node:)
        @children << node
      end

      def add_leaf(entry:)
        @entry = entry
      end
    end
  end
end
