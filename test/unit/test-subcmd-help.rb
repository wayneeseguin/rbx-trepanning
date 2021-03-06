#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../processor/main'
# require_relative '../../app/core'

# Mock debugger stub. FIXME: put in comment helper routine.
class Trepan
end

# Test Trepan::CmdProcessor
class TestSubCmdHelp < Test::Unit::TestCase

  def setup
    @dbg     = Trepan.new
    # @core    = Trepan::Core.new(@dbg)
    @cmdproc = Trepan::CmdProcessor.new(@dbg)
    @cmds    = @cmdproc.instance_variable_get('@commands')
  end

  # See that subcommand class constants exist.
  def test_required_class_constants
    puts 'Still need HELP const for subcmds?'
    @cmds.each do |cmd_name, cmd|
      if cmd.is_a?(Trepan::SubcommandMgr)
        cmd.subcmds.subcmds.each do |subcmd_name, subcmd|
          where = "of subcommand #{subcmd_name} in command #{cmd_name}"
          # %w(HELP NAME SHORT_HELP).each do
          %w(NAME SHORT_HELP).each do
            |const|
            value = subcmd.my_const(const)
            assert_equal(true, value.is_a?(String),
                         "#{const} #{where} should be a String; got #{value}.")
          end
          value = subcmd.my_const('MIN_ABBREV')
          assert(value.is_a?(Fixnum),
                 "MIN_ABBREV #{where} should be a Fixnum; got #{value}.")

          if 'show' == cmd_name
            short_help = subcmd.my_const('SHORT_HELP')
            needed_start = 'Show '
            assert_equal(needed_start, short_help[0..needed_start.size-1],
                         "Short help #{where} should start: \"#{needed_start}\"; got #{short_help}")
          end
        end
      end
    end
  end


end
