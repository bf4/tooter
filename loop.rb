require 'bundler/setup'
require_relative 'app'
@minutes = 30
def mem_usage
  p cmd =  "ps aux | grep 'ruby #{$0}' | awk '{sum +=$4}; END {print sum}'"
  mem_usage = `#{cmd}`.strip
  p "script memory usage #{mem_usage}"
  mem_usage
end
def run
  mem_usage
  p "Beginning run #{Time.now}"
  p1 = fork { App.run && mem_usage && exit(0) }
  p Process.waitpid2(p1)
  p "Ending Running #{Time.now}. Sleeping #{@minutes} minutes"
end
loop {
  run
  sleep 60*@minutes
  p "Done sleeping at #{Time.now}"
}
