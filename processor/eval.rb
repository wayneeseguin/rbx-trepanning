# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
class Trepan
  class CmdProcessor

    def debug_eval(str, max_fake_filename=15)
      begin
        debug_eval_with_exception(str, max_fake_filename)
      rescue SyntaxError, StandardError, ScriptError => e
        exception_dump(e, @settings[:stack_trace_on_error], $!.backtrace)
        nil
      end
    end

    def debug_eval_with_exception(str, max_fake_filename=15)
      @frame.run(str, fake_eval_filename(str, max_fake_filename))
    end

    def debug_eval_no_errmsg(str, max_fake_filename=15)
      begin
        debug_eval_with_exception(str, max_fake_filename)
      rescue SyntaxError, StandardError, ScriptError => e
        nil
      end
    end

    def eval_code(str, max_fake_filename)
      obj = debug_eval(str, max_fake_filename)
      
      idx = @user_variables
      @user_variables += 1
      
      str = "$d#{idx}"
      Rubinius::Globals[str.to_sym] = obj
      msg "#{str} = #{obj.inspect}"
      obj
    end

    def exception_dump(e, stack_trace, backtrace)
      str = "#{e.class} Exception:\n\t#{e.message}"
      if stack_trace
        str += "\n" + backtrace.map{|l| "\t#{l}"}.join("\n") rescue nil
      end
      msg str
      # throw :debug_error
    end

    def fake_eval_filename(str, maxlen = 15)
      fake_filename = 
        if maxlen < str.size
          # FIXME: Guard against \" in positions 13..15?
          str.inspect[0..maxlen-1] + '"...'
        else
          str.inspect
        end
      "(eval #{fake_filename})"
    end
    
  end
end

if __FILE__ == $0
  # Demo it.
  cmdp = Trepan::CmdProcessor.new
  puts cmdp.fake_eval_filename('x = 1; y = 2')
  puts cmdp.fake_eval_filename('x = 1; y = 2', 7)
  def cmdp.errmsg(msg)
    puts "** #{msg}"
  end
  def cmdp.msg(msg)
    puts "#{msg}"
  end
  begin 
    1/0
  rescue Exception => exc
    cmdp.exception_dump(exc, true, $!.backtrace)
    puts '=' * 40
  end

  x = 10

  require 'rubygems'; require 'require_relative'
  require_relative '../app/frame'
  frame = Trepan::Frame.new(self, 1, Rubinius::VM.backtrace(0)[0])
  cmdp.instance_variable_set('@frame', frame)
  cmdp.instance_variable_set('@settings', {:stack_trace_on_error => true})
  def cmdp.errmsg(mess) ; puts mess end
  # require_relative '../lib/trepanning'
  # Trepan.start
  puts cmdp.debug_eval('x = "#{x}"')
  puts '=' * 40
  puts cmdp.debug_eval('x+')
  puts cmdp.debug_eval_no_errmsg('y+')
  puts '=' * 40
  puts cmdp.debug_eval('x+')
  puts cmdp.debug_eval('y = 1; x+', 4)
end
