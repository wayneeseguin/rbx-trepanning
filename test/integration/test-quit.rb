#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'helper'

class TestQuit < Test::Unit::TestCase
  @@NAME = File.basename(__FILE__, '.rb')[5..-1]

  def test_trepanx_call
    assert_equal(true, run_debugger(@@NAME, 'null.rb'))
  end

  def test_xcode_call
    startup_file = File.join(ENV['HOME'], '.rbxrc')
    lines = File.open(startup_file).readlines.grep(/Trepan\.start/)
    if lines && lines.any?{|line| line.grep(/:Xdebug/)}
      no_error = run_debugger('quit-Xdebug', 'null.rb',
                              {:xdebug => true,
                                :short_cmd => @@NAME,
                                :do_diff => false
                              })
      assert_equal(true, no_error)
      if no_error
        outfile = File.join(File.dirname(__FILE__), 'quit-Xdebug.out')
        FileUtils.rm(outfile)
      end
    else
      puts "Trepan.start(:skip_loader=>:Xdebug) is not in ~.rbxrc. Skipping."
      assert true
    end
  end
end
