require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::EvalCommand < Trepan::Command

  CATEGORY      = 'data'
  HELP    = <<-HELP
Run code in the context of the current frame.

The value of the expression is stored into a global variable so it
may be used again easily. The name of the global variable is printed
next to the inspect output of the value.
      HELP

  NAME          = File.basename(__FILE__, '.rb')
  NEED_STACK    = true
  SHORT_HELP    = 'Run code in the current context'
  def run(args)
    @proc.debug_eval(@proc.cmd_argstr, @proc.settings[:maxstring])
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  arg_str = '1 + 2'
  ## cmd.proc.instance_variable_set('@cmd_argstr', arg_str)
  dbgr.instance_variable_set('@cmd_argstr', arg_str)

  ## cmd.run([cmd.name, arg_str])
end
