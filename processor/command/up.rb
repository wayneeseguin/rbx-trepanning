# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require '/home/rocky-rvm/.rvm/src/rbx-trepanning/processor/command/base/cmd'
require_relative 'base/cmd'

# up command. Like 'down' butthe direction (set by DIRECTION) is different.
#
# NOTE: The down command  subclasses this, so beware when changing! 
class Trepan::Command::UpCommand < Trepan::Command

  # Silence already initialized constant .. warnings
  old_verbose = $VERBOSE  
  $VERBOSE    = nil
  HELP        = 
"u(p) [count]

Move the current frame up in the stack trace (to an older frame). 0 is
the most recent frame. If no count is given, move up 1.

See also 'down' and 'frame'.
"

  ALIASES       = %w(u)
  CATEGORY      = 'stack'
  MAX_ARGS      = 1  # Need at most this many
  NAME          = File.basename(__FILE__, '.rb')
  NEED_STACK    = true
  SHORT_HELP    = 'Move frame in the direction of the caller of the last-selected frame'
  $VERBOSE      = old_verbose 

  def initialize(proc)
    super
    @direction = +1 # -1 for down.
  end

  # Run 'up' command. 
  def run(args)

    # FIXME: move into @proc and test based on NEED_STACK.
    if @proc.stack_size == 0
      errmsg('No frames recorded.')
      return false
    end

    if args.size == 1
      # Form is: "down" which means "down 1"
      count = 1
    else
      count_str = args[1]
      name_or_id = args[1]
      opts = {
        :msg_on_error => 
        "The '#{NAME}' command argument must eval to an integer. Got: %s" % count_str,
        :min_value => -@proc.stack_size,
        :max_value => @proc.stack_size-1
      }
      count = @proc.get_an_int(count_str, opts)
      return false unless count
    end
    @proc.adjust_frame(@direction * count, false)
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)

  # def sep ; puts '=' * 40 end
  # cmd.run [name]
  # %w(-1 0 1 -2).each do |count| 
  #   puts "#{name} #{count}"
  #   cmd.run([name, count])
  #   sep 
  # end
  # def foo(cmd, name)
  #   puts "#{name}"
  #   cmd.run([name])
  #   sep
  #   %w(-2 -1).each do |count| 
  #     puts "#{name} #{count}"
  #     cmd.run([name, count])
  #     sep 
  #   end
  # end
  # foo(cmd, name)
end