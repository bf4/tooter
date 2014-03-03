module Colorize
  module Text
    module_function
    def black(msg, bold=false)
      colorize("30m", msg, bold)
    end
    def red(msg, bold=false)
      colorize("31m", msg, bold)
    end
    def green(msg, bold=false)
      colorize("32m", msg, bold)
    end
    def yellow(msg, bold=false)
      colorize("33m", msg, bold)
    end
    def blue(msg, bold=false)
      colorize("34m", msg, bold)
    end
    def magenta(msg, bold=false)
      colorize("35m", msg, bold)
    end
    def cyan(msg, bold=false)
      colorize("36m", msg, bold)
    end
    def white(msg, bold=false)
      colorize("37m", msg, bold)
    end
    def colorize(ansi_code, msg, bold)
      "\033[#{bold ? '1;' : '0;'}#{ansi_code}#{msg}\033[0m"
    end
  end
  module Background
    module_function
    def black(msg, bold=false)
      colorize("40m", msg, bold)
    end
    def red(msg, bold=false)
      colorize("41m", msg, bold)
    end
    def green(msg, bold=false)
      colorize("42m", msg, bold)
    end
    def yellow(msg, bold=false)
      colorize("43m", msg, bold)
    end
    def blue(msg, bold=false)
      colorize("44m", msg, bold)
    end
    def magenta(msg, bold=false)
      colorize("45m", msg, bold)
    end
    def cyan(msg, bold=false)
      colorize("46m", msg, bold)
    end
    def white(msg, bold=false)
      colorize("47m", msg, bold)
    end
    def colorize(ansi_code, msg, bold)
      "\033[#{bold ? '1;' : '0;'}#{ansi_code}#{msg}\033[0m"
    end
  end
end
