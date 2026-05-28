# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

module RubyLsp
  module Hanami
    class RoutesWalkerTest < Minitest::Test
      def test_processes_block_style_routes
        Dir.mktmpdir do |dir|
          config_dir = File.join(dir, "config")
          FileUtils.mkdir_p(config_dir)
          routes_file = File.join(config_dir, "routes.rb")
          File.write(routes_file, <<~RUBY)
            module MyApp
              class Routes < Hanami::Routes
                slice :main, at: "/" do
                  get "/authors", to: "authors.index"
                end
              end
            end
          RUBY

          walker = RoutesWalker.new(project_root: dir)
          routes = walker.walk_routes_file

          assert_equal 1, routes.length
          assert_equal "main", routes[0][:containing_slice]
          assert_equal :get, routes[0][:type]
          assert_equal "authors.index", routes[0][:key]
          assert_equal "/authors", routes[0][:route]
        end
      end

      def test_processes_inline_style_routes
        Dir.mktmpdir do |dir|
          config_dir = File.join(dir, "config")
          FileUtils.mkdir_p(config_dir)
          routes_file = File.join(config_dir, "routes.rb")
          File.write(routes_file, <<~RUBY)
            module MyApp
              class Routes < Hanami::Routes
                get "/books", to: "books.index"
              end
            end
          RUBY

          walker = RoutesWalker.new(project_root: dir)
          routes = walker.walk_routes_file

          assert_equal 1, routes.length
          assert_nil routes[0][:containing_slice]
          assert_equal :get, routes[0][:type]
          assert_equal "books.index", routes[0][:key]
          assert_equal "/books", routes[0][:route]
        end
      end
    end
  end
end
