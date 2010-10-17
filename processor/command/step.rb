require 'rubygems'; require 'require_relative'
require_relative './next'

class Trepan::Command::StepCommand < Trepan::Command

  ALIASES      = %w(s)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
Behaves like 'next', but if there is a method call on the current line,
execption is stopped in the called method.
      HELP
  NEED_RUNNING = true
  SHORT_HELP   = 'Step into next method call or to next line'

  def run(args)
    @proc.step_return_to_program(@proc.step_over_by(1))
  end
end

