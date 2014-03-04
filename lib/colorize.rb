# see https://github.com/rubychan/coderay/blob/master/lib/coderay/encoders/terminal.rb
# https://rubygems.org/gems/text-highlight
module Colorize
  ESCAPE_CODES_PATTERN = Regexp.new('\e\[(?:\d;)?\d{1,2}m')
  module ColorCode
    module_function
    def color(name, background=false)
      number = case name
               when 'black'   then 30
               when 'red'     then 31
               when 'green'   then 32
               when 'yellow'  then 33
               when 'blue'    then 34
               when 'magenta' then 35
               when 'cyan'    then 36
               when 'white'   then 37
               else fail "No code for color #{name}"
               end
      number = number + 10 if background
      "#{number}m"
    end
  end

  module_function

  def escape_codes(string)
    string.to_s.scan(ESCAPE_CODES_PATTERN)
  end

  def escape_code_start
    "\033"
  end

  def escape_code_reset
    "\033[0m"
  end

  def escape_code_color(ansi_code, bold=false)
     "[#{bold ? '1;' : '0;'}#{ansi_code}"
  end

  def colorize(ansi_code, msg, bold)
    "\033[#{bold ? '1;' : '0;'}#{ansi_code}#{msg}\033[0m"
  end

  module Text
    module_function
    def black(msg, bold=false)
      Colorize.colorize("30m", msg, bold)
    end
    def red(msg, bold=false)
      Colorize.colorize("31m", msg, bold)
    end
    def green(msg, bold=false)
      Colorize.colorize("32m", msg, bold)
    end
    def yellow(msg, bold=false)
      Colorize.colorize("33m", msg, bold)
    end
    def blue(msg, bold=false)
      Colorize.colorize("34m", msg, bold)
    end
    def magenta(msg, bold=false)
      Colorize.colorize("35m", msg, bold)
    end
    def cyan(msg, bold=false)
      Colorize.colorize("36m", msg, bold)
    end
    def white(msg, bold=false)
      Colorize.colorize("37m", msg, bold)
    end
  end
  module Background
    module_function
    def black(msg, bold=false)
      Colorize.colorize("40m", msg, bold)
    end
    def red(msg, bold=false)
      Colorize.colorize("41m", msg, bold)
    end
    def green(msg, bold=false)
      Colorize.colorize("42m", msg, bold)
    end
    def yellow(msg, bold=false)
      Colorize.colorize("43m", msg, bold)
    end
    def blue(msg, bold=false)
      Colorize.colorize("44m", msg, bold)
    end
    def magenta(msg, bold=false)
      Colorize.colorize("45m", msg, bold)
    end
    def cyan(msg, bold=false)
      Colorize.colorize("46m", msg, bold)
    end
    def white(msg, bold=false)
      Colorize.colorize("47m", msg, bold)
    end
  end
end
