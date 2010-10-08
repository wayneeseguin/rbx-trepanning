require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoBreakpoints < Trepan::Subcommand
  MIN_ABBREV   = 'br'.size
  NAME         = File.basename(__FILE__, '.rb')
  PREFIX       = %w(info breakpoints)
  SHORT_HELP   = 'Status of user-settable breakpoints'
  
  def run(args)
    # FIXME: Originally was 
    #   section "Breakpoints"
    # Add section? 

    show_all = 
      if args.size > 2
        opts = {
        :msg_on_error => 
        "An '#{PREFIX.join(' ')}' argument must eval to a breakpoint between 1..#{@proc.brkpts.max}.",
        :min_value => 1,
        :max_value => @proc.brkpts.max
      }
        bp_nums = @proc.get_int_list(args[2..-1])
        false
      else
        true
      end

    bpmgr = @proc.brkpts
    if bpmgr.empty? && @proc.dbgr.deferred_breakpoints.empty?
      msg('No breakpoints.')
    else
      # There's at least one
      bpmgr.list.each do |bp|
        msg "%3d: %s" % [bp.id, bp.describe]
      end
      msg('Deferred breakpoints...')
      @proc.dbgr.deferred_breakpoints.each_with_index do |bp, i|
        if bp
          msg "%3d: %s" % [i+1, bp.describe]
        end
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Trepan::Subcommand::InfoBreakpoints.new(cmd)

  # puts '-' * 20
  # subcommand.run(%w(info break))
  puts '-' * 20
  subcommand.summary_help(name)
  puts
  puts '-' * 20
end
