require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'

class Trepan::Command::ContinueCommand < Trepan::Command
  ALIASES      = %w(c cont)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
  NEED_RUNNING = true
Continue execution until another breakpoint is hit.
      HELP
  SHORT_HELP   =  'Continue running the target thread'

  def run(args)
    @proc.dbgr.listen
  end
end

if __FILE__ == $0
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)
end