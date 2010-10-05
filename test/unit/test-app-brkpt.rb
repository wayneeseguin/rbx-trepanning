#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/breakpoint'

class TestAppBrkpt < Test::Unit::TestCase

  def test_basic
    method = Rubinius::CompiledMethod.of_sender
    b1 = Trepanning::BreakPoint.new '<start>', method, 1, 2, 0
    assert_equal(false, b1.temp?)
    assert_equal(0, b1.hits)
    assert_equal('B', b1.icon_char)
    # assert_equal(true, b1.condition?)
    # assert_equal(1, b1.hits)
    # assert_equal(b1.source_container, tf.source_container)
    b1.enabled = false
    assert_equal('b', b1.icon_char)
    # assert_raises TypeError do 
    #   Trepanning::Breakpoint.new(iseq, iseq.iseq_size, :temp => true)
    # end
    # assert_raises TypeError do 
    #   Trepanning::Breakpoint.new(0, 5)
    # end
    # require_relative '../../lib/trepanning.rb'
    # b2 = Trepanning::Breakpoint.new(iseq, 0, :temp => true)
    # assert_equal('t', b2.icon_char)
  end
end
