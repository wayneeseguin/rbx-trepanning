# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::ShowAutoEval < Trepan::ShowBoolSubSubcommand
  unless defined?(HELP)
    HELP = "set auto eval [ON|OFF]

Set this on if you want things that don't look like debugger command to be eval'd
as a string."

    MIN_ABBREV   = 'ev'.size
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %w(show auto eval)
    SHORT_HELP = "Show evaluation of unrecognized debugger commands"
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../../../subcmd'

  # FIXME: DRY the below code
  dbgr, show_cmd = MockDebugger::setup('show', false)
  testcmdMgr     = Trepan::Subcmd.new(show_cmd)
  auto_cmd       = Trepan::SubSubcommand::ShowAuto.new(dbgr.processor, 
                                                       show_cmd)

  # FIXME: remove the 'join' below
  cmd_name       = Trepan::SubSubcommand::ShowAutoEval::PREFIX.join('')
  autox_cmd      = Trepan::SubSubcommand::ShowAutoEval.new(show_cmd.proc, auto_cmd,
                                                           cmd_name)
  # # require_relative '../../../../lib/trepanning'
  # # dbgr = Trepan.new(:set_restart => true)
  # # dbgr.debugger
  autox_cmd.run([])

end
