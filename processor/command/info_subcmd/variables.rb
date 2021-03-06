require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Command::InfoVariables < Trepan::Subcommand
  MIN_ABBREV   = 'var'.size
  NAME         = File.basename(__FILE__, '.rb')
  NEED_STACK   = true
  PREFIX       = %w(info variables)
  SHORT_HELP   = 'Display the value of a variable or variables'
  HELP         = <<-HELP
Show debugger variables and user created variables. By default,
shows all variables.

The optional argument is which variable specifically to show the value of.
      HELP
  
  def run(args)
    if args.size == 2
      @proc.dbgr.variables.each do |name, val|
        msg "var '#{name}' = #{val.inspect}"
      end
      
      if @proc.dbgr.user_variables > 0
        section "User variables"
        (0...@proc.dbgr.user_variables).each do |i|
          str = "$d#{i}"
          val = Rubinius::Globals[str.to_sym]
          msg "var #{str} = #{val.inspect}"
        end
      end
    else
      var = args[2]
      if @proc.dbgr.variables.key?(var)
        msg "var '#{var}' = #{variables[var].inspect}"
      else
        msg "No variable set named '#{var}'"
      end
    end
  end
end
