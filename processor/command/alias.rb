# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'

class Trepan::Command::AliasCommand < Trepan::Command

  unless defined?(HELP)
    HELP = 
"alias ALIAS COMMAND

Add an alias for a COMMAND

See also 'unalias'.
"

    CATEGORY      = 'support'
    MAX_ARGS      = 2  # Need at most this many
    NAME          = File.basename(__FILE__, '.rb')
    NEED_STACK    = true
    SHORT_HELP    = 'Add an alias for a debugger command'
  end
  
  # Run command. 
  def run(args)
    if args.size == 1
      puts "show not finished yet :o("
      ## @proc.commands['show'].run(%w(show alias))
    elsif args.size == 2
      puts "this show not finished yet either :o("
      ## @proc.commands['show'].run(%W(show alias #{args[1]}))
    else
      junk, al, command = args
      old_command = @proc.aliases[al]
      if @proc.commands.member?(command)
        @proc.aliases[al] = command
        if old_command
          msg("Alias '#{al}' for command '#{command}' replaced old " + 
              "alias for '#{old_command}'.")
        else
          msg "New alias '#{al}' for command '#{command}' created."
        end
      else
        errmsg "You must alias to a command name, and '#{command}' isn't one."
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)
  cmd.run %w(alias yy foo)
  cmd.run %w(alias)
  cmd.run %w(alias yy next)
end
