# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
# The main "driver" class for a command processor. Other parts of the 
# command class and debugger command objects are pulled in from here.

require 'set'
require 'pathname'  # For cleanpath

require 'rubygems'; require 'require_relative'
## %w(default display eventbuf eval load_cmds location frame hook msg 
##    validate).each do
%w(default breakpoint disassemble eval load_cmds location frame hook msg 
   running stepping validate).each do
  |mod_str|
  require_relative mod_str
end
## require_relative '../app/brkptmgr'

class Trepan
  class CmdProcessor

    # SEE ALSO attr's in require_relative's of loop above.

    attr_reader   :cmd_name        # command name before alias or macro resolution
    attr_reader   :cmd_argstr      # Current command args, a String.
                                   # This is current_command with the command
                                   # name removed from the beginning.
    ## attr_reader   :core            # Trepan core object
    attr_reader   :current_command # Current command getting run, a String.
    attr_accessor   :dbgr          # Trepan instance (via
                                   # Trepan::Core instance)
                                   ## FIXME 1.9.2 has attr_reader !
    attr_accessor :debug_nest      # Number of nested debugs. Used in showing
                                   # prompt.
    attr_accessor :different_pos   # Same type as settings[:different] 
                                   # this is the temporary value for the
                                   # next stop while settings is the default
                                   # value to use.
    attr_accessor :event           # Stop event
    attr_accessor :leave_cmd_loop  # Commands set this to signal to leave
                                   # the command loop (which often continues to 
                                   # run the debugged program). 
    attr_accessor :line_no         # Last line shown in "list" command
    attr_accessor :next_thread     # Thread. If non-nil then in
                                   # stepping the thread has to be
                                   # this thread.
    attr_accessor :pass_exception  # Pass an exception back 
    attr_accessor :prompt          # String print before requesting input
    attr_reader   :settings        # Hash[:symbol] of command
                                   # processor settings
    attr_reader   :step_bp

    # The following are used in to force stopping at a different line
    # number. FIXME: could generalize to a position object.
    attr_accessor :last_pos       # Last position. 6-Tuple: of
                                  # [location, container, stack_size, 
                                  #  current_thread, pc_offset]


    unless defined?(EVENT2ICON)
      # Event icons used in printing locations.
      EVENT2ICON = {
        'brkpt'          => 'xx',
        'tbrkpt'         => 'x1',
        'c-call'         => 'C>',
        'c-return'       => '<C',
        'step-call'      => '->',
        'call'           => '->',
        'class'          => '::',
        'coverage'       => '[]',
        'debugger-call'  => ':o',
        'end'            => '-|',
        'line'           => '--',
        'raise'          => '!!',
        'return'         => '<-',
        'start'          => '>>',
        'start'          => '>>',
        'switch'         => 'sw',
        'trace-var'      => '$V',
        'unknown'        => '?!',
        'vm'             => 'VM',
        'vm-insn'        => '..',
      } 
      # These events are important enough event that we always want to
      # stop on them.
      UNMASKABLE_EVENTS = Set.new(['end', 'raise', 'unknown'])
    end

    def initialize(dbgr, settings={})
      @dbgr            =  dbgr
      @debug_nest      = 1
      @hidelevels      = {}
      @last_command    = nil
      @last_pos        = [nil, nil, nil, nil, nil, nil]
      @next_thread     = nil
      @user_variables = 0
      

      start_cmds       = settings.delete(:start_cmds)
      start_file       = settings.delete(:start_file)

      @settings        = settings.merge(DEFAULT_SETTINGS)
      @different_pos   = @settings[:different]

      # FIXME: Rework using a general "set substitute file" command and
      # a global default profile which gets read.
      prelude_file = File.expand_path(File.join(File.dirname(__FILE__), 
                                                %w(.. data prelude.rb)))

      ## Start with empty thread and frame info.
      frame_teardown 

      # Run initialization routines for each of the "submodule"s.
      # load_cmds has to come first.
      ## %w(load_cmds breakpoint display eventbuf frame running validate
      ##   ).each do |submod|
      %w(load_cmds breakpoint frame running validate).each do |submod|
        self.send("#{submod}_initialize")
      end
      hook_initialize(commands)
    end

    def canonic_container(container)
      [container[0], canonic_file(container[1])]
    end

    def canonic_file(filename)
      # For now we want resolved filenames 
      @settings[:basename] ? File.basename(filename) : 
        # Cache this?
        Pathname.new(filename).cleanpath.to_s
    end

    def compute_prompt
      th = @current_thread
      thread_str = 
        if 2 == Thread.list.size
          ''
        elsif th == Thread.main
          '@main'
        else
          "@#{th.current.object_id}"
        end
      "%s#{settings[:prompt]}%s%s: " % 
        ['(' * @debug_nest, thread_str, ')' * @debug_nest]
      
    end

    # Check that we meed the criteria that cmd specifies it needs
    def ok_for_running(cmd, name, nargs)
      # TODO check execution_set against execution status.
      # Check we have frame is not null
      min_args = cmd.class.const_get(:MIN_ARGS)
      if nargs < min_args
        errmsg(("Command '%s' needs at least %d argument(s); " + 
                "got %d.") % [name, min_args, nargs])
        return false
      end
      max_args = cmd.class.const_get(:MAX_ARGS)
      if max_args and nargs > max_args
        errmsg(("Command '%s' needs at most %d argument(s); " + 
                "got %d.") % [name, max_args, nargs])
        return false
      end
      # if cmd.class.const_get(:NEED_RUNNING) && !...
      #   errmsg "Command '%s' requires a running program." % name
      #   return false
      # end

      if cmd.class.const_get(:NEED_STACK) && !@frame
        errmsg "Command '%s' requires a running stack frame." % name
        return false
      end

      return true
    end

    # Run one debugger command. True is returned if we want to quit.
    def process_command_and_quit?()
      intf = @dbgr.intf
      return true if intf[-1].input.eof? && intf.size == 1
      while !intf[-1].input.eof? || intf.size > 1
        begin
          @current_command = read_command().strip
          if @current_command.empty? 
            if @last_command && intf[-1].interactive?
              @current_command = @last_command 
            else
              next
            end
          end
          next if @current_command[0..0] == '#' # Skip comment lines
          break
        rescue IOError, Errno::EPIPE
          if @dbgr.intf.size > 1
            @dbgr.intf.pop 
            @last_command = nil
            print_location
          else
            msg "That's all folks..."
            ## FIXME: think of something better.
            quit('exit!')
            return true
          end
        end
      end
      leave_cmdloop = run_command(@current_command)

      # Save it to the history.
      @dbgr.history_io.puts @last_command
    end

    def after_cmdloop
      @cmdloop_posthooks.run
    end

    def before_cmdloop

      frame_setup

      @unconditional_prehooks.run
      if breakpoint?
        delete_breakpoint(@brkpt) if @brkpt.temp?
        @last_pos = [@frame.vm_location, @stack_size, @current_thread, @event] 
      else
        if stepping_skip? # || @stack_size <= @hide_level
          step(@return_to_program, @step_count)
          return true
        elsif @event == 'start'
          step('step', 0)
          return true
        end
      end

      @prompt = "(#{@settings[:prompt]}): " # compute_prompt

      @leave_cmd_loop = false
      print_location unless @settings[:traceprint]
      # if 'trace-var' == @event 
      #   msg "Note: we are stopped *after* the above location."
      # end

      # @eventbuf.add_mark if @settings[:tracebuffer]
      
      @return_to_program = false
      @cmdloop_prehooks.run
      return false
    end


    # This is the main entry point.
    def process_commands
      skip_command = before_cmdloop
      while not @leave_cmd_loop do
        begin
          if !skip_command 
            break if process_command_and_quit?()
          end
          if @return_to_program
            after_cmdloop
            if @step_count >= 0 && 'finish' != @return_to_program
              @step_bp = step_over_by(1)
              run_command('disassemble') if settings[:debugstep]
              dbgr.listen('step' == @return_to_program)
            else
              @step_bp = nil
              dbgr.listen
            end
            skip_command = before_cmdloop
          end
        rescue SystemExit
          ## @dbgr.stop
          raise
        rescue Exception => exc
          errmsg("Internal debugger error: #{exc.inspect}")
          exception_dump(exc, @settings[:debugexcept], $!.backtrace)
        end
      end
      after_cmdloop
    end

    # Run current_command, a String. @last_command is set after the
    # command is run if it is a command.
    def run_command(current_command)
      eval_command = 
        if current_command[0..0] == '!'
          current_command[0] = ''
        else
          false
        end

      unless eval_command
        # Expand macros. FIXME: put in a procedure
        args = current_command.split
        while true do
          macro_cmd_name = args[0]
          return false if args.size == 0
          break unless @macros.member?(macro_cmd_name)
          current_command = @macros[macro_cmd_name].call(*args[1..-1])
          msg current_command if settings[:debugmacro]
          if current_command.is_a?(Array) && 
              current_command.any {|val| !val.is_a?(String)}
            args = current_command
          elsif current_command.is_a?(String)
            args = current_command.split
          else
            errmsg("macro #{macro_cmd_name} should return an Array " +
                   "of Strings or a String. Got #{current_command.inspect}")
            return false
          end
        end

        @cmd_name = args[0]
        run_cmd_name = 
          if @aliases.member?(@cmd_name)
            @aliases[@cmd_name] 
          else
            @cmd_name
          end
            
        if @commands.member?(run_cmd_name)
          cmd = @commands[run_cmd_name]
          if ok_for_running(cmd, run_cmd_name, args.size-1)
            @cmd_argstr = current_command[@cmd_name.size..-1].lstrip
            cmd.run(args) 
            @last_command = current_command
          end
          return false
        end
      end

      # Eval anything that's not a command or has been
      # requested to be eval'd
      if settings[:autoeval] || eval_command
        eval_code(current_command, @settings[:maxstring])
      else
        undefined_command(cmd_name)
      end
      return false
    end

    # Error message when a command doesn't exist
    def undefined_command(cmd_name)
      errmsg('Undefined command: "%s". Try "help".' % cmd_name)
    end

    # FIXME: Allow access to both Trepan::CmdProcessor and Trepan
    # for index [] and []=.
    # If there is a Trepan::CmdProcessor setting that would take precidence.
    # def settings
    #   @settings.merge(@dbgr.settings) # wrong because this doesn't allow []=
    # end
  end
end

if __FILE__ == $0
  $0 = 'foo' # So we don't get here again
  require_relative '../lib/trepanning'
  dbg =  Trepan.new(:nx => true)
  cmdproc = dbg.instance_variable_get('@processor')
  cmdproc.msg('I am main')
  cmdproc.errmsg('Whoa!')
  cmds = cmdproc.commands
  p cmdproc.aliases
  p cmdproc.commands.keys.sort
  cmd_name, cmd_obj = cmds.first
  puts cmd_obj.class.const_get(:HELP)
  puts cmd_obj.class.const_get(:SHORT_HELP)

  cmdproc.instance_variable_set('@current_thread', Thread.current)
  puts cmdproc.compute_prompt
  Thread.new{ puts cmdproc.compute_prompt }.join

  x = Thread.new{ Thread.pass; x = 1 }
  puts cmdproc.compute_prompt
  x.join
  cmdproc.debug_nest += 1
  puts cmdproc.compute_prompt

  # if ARGV.size > 0
  #   cmdproc.msg('Enter "q" to quit')
  #   cmdproc.process_commands
  # else
  #   $input = []
  #   class << cmdproc
  #     def read_command
  #       $input.shift
  #     end
  #   end
  #   $input = ['1+2']
  #   cmdproc.process_command_and_quit?
  #   $input = ['!s = 5']  # ! means eval line 
  #   cmdproc.process_command_and_quit?
  # end
end
