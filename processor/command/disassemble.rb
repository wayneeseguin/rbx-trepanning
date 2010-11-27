require 'rubygems'; require 'require_relative'
require_relative './base/cmd'
require_relative '../../app/iseq'

class Trepan::Command::DisassembleCommand < Trepan::Command
  NAME         = File.basename(__FILE__, '.rb')
  ALIASES      = %w(dis)
  CATEGORY     = 'data'
  HELP         = <<-HELP
#{NAME} [all|method]

Disassembles Rubinius VM instructins. By default, the bytecode for the
current line is disassembled only.

If a method name is given, disassemble just that method. If the
argument is 'all', the entire method is shown as bytecode.

    HELP

  NEED_STACK   = true
  SHORT_HELP   = 'Show the bytecode for the current method'

  def disassemble_method(meth)
    frame_ip = (@proc.frame.method == meth) ? @proc.frame.ip : nil
    lines = meth.lines
    next_line_ip = 0
    next_i = 1
    meth.decode.each do |insn|
      show_line = 
        if insn.ip >= next_line_ip
          next_line_ip = lines.at(next_i+1)
          line_no = lines.at(next_i)
          next_i += 2
          true
        else
          false
        end
          
      prefix = Trepanning::ISeq::disasm_prefix(insn.ip, frame_ip, meth)
      str = "#{prefix} #{insn}"
      if show_line
        str += 
          if insn.instance_variable_get('@comment')
            ' '
          elsif str[-1..-1] !~/\s/
            '    '
          else
            ''
          end
        str += "# line: #{line_no}"  
      end
      msg str
    end
  end

  def run(args)
    if 1 == args.size
      @proc.show_bytecode
    elsif 'all' == args[1]
      # FIXME: first msg is a section command.
      msg "Bytecode for #{@proc.frame.location.describe}"
      disassemble_method(current_method)
    else
      str = "method(#{args[1].inspect}.to_sym)"
      puts str
      meth = @proc.debug_eval_no_errmsg(str)
      if meth
        # FIXME: first msg is a section command.
        msg "Bytecode for method #{args[1]}"
        disassemble_method(meth.executable)
      else
        errmsg "Method #{args[1]} not found"
      end
    end
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  def foo(cmd)
    puts "#{cmd.name}"
    cmd.run([cmd.name])
    puts '=' * 40
    puts "#{cmd.name} all"
    cmd.run([cmd.name, 'all'])
  end
  foo(cmd)
end
