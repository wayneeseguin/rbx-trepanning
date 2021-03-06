require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::BacktraceCommand < Trepan::Command
  ALIASES      = %w(bt where)
  CATEGORY     = 'stack'
  NAME         = File.basename(__FILE__, '.rb')
  HELP = <<-HELP
Show the call stack as a simple list.

Passing "-v" will also show the values of all locals variables
in each frame.
      HELP
  NEED_STACK   = true
  SHORT_HELP   =  'Show the current call stack'
  
  def run(args)
    arg_str = args[1..-1].join(' ')
    verbose = (arg_str =~ /-v/)

    count = 
      if m = /(\d+)/.match(arg_str)
        m[1].to_i
      else
        proc.stack_size
    end
    
    msg "Backtrace:"
    
    @proc.dbgr.each_frame(@proc.top_frame) do |frame|
      return if count and frame.number >= count


      prefix = (frame == @proc.frame) ? '-->' : '   '
      msg "%s #%d %s" % [prefix, frame.number, 
                         frame.describe(:show_ip => verbose)]
      
      if verbose
        frame.local_variables.each do |local|
          msg "       #{local} = #{frame.run(local.to_s).inspect}"
        end
      end
    end
  end
end

