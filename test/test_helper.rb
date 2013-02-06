# encoding: UTF-8

if RUBY_VERSION >= '1.9'
  require 'simplecov'

  SimpleCov.command_name('Unit Tests')
  SimpleCov.start do
    add_filter '/test/'
  end
end

require 'rubygems'
require 'minitest/autorun'
require 'minitest/reporters' if RUBY_VERSION >= '1.9'

RAILS_VERSION = ENV['RAILS_VERSION'] || '~> 3.2.0'
gem 'activesupport', RAILS_VERSION

require 'active_support'
require 'active_support/core_ext'
require File.join(File.dirname(__FILE__), %w{ .. lib google_maps_tools })

puts "Ruby version #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} - #{RbConfig::CONFIG['RUBY_INSTALL_NAME']}"

$KCODE = 'u' if RUBY_VERSION.to_f < 1.9

module TestHelper
end

if RUBY_VERSION >= '1.9'
  MiniTest::Reporters.use!(MiniTest::Reporters::SpecReporter.new)
end

