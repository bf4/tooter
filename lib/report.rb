root = File.expand_path('..', File.dirname(__FILE__))
require File.join(root, 'app')
require 'colorize'
require 'English'
class App::Report
  include Enumerable

  def initialize(store)
    @store = store
  end

  def print
    each do |tweet|
      print_tweet(tweet)
    end
  end

  def print_tweet(tweet)
    puts
    puts %w(full_text user created_at id).map(&:intern).
      map{|attr| tweet[attr] }.
      join("\n\t")
    puts
  end

  def search(term)
    pattern = term.is_a?(Regexp) ? term : /#{term}/
    select do |tweet|
      tweet[:full_text] =~ pattern
    end
  end

  def each
    @store.read do |store|
      store.roots.each do |key|
        yield tweet = store[key]
      end
    end
  end

end

if $0 == __FILE__
  filename = App.root.join('tweets').to_s
  store = Store.new(filename)
  report = App::Report.new(store)
  pattern = ARGV[0] || /ruby/
  results = report.search(pattern)
  # results = [
  #   {
  #     :created_at => 'some time',
  #     :full_text  => 'something with ruby in it',
  #     :id         => '5',
  #     :user_name  => 'schmo',

  #   }
  # ]
  results.each do |tweet|
    # report.print_tweet(tweet)
    created_at = Colorize::Text.green       tweet[:created_at]
    c_text = Colorize::Text.yellow(tweet[:full_text]).gsub(pattern) do
      prematch  = $PREMATCH #$`
      term      = $MATCH # $&
      postmatch = $POSTMATCH # $'
      start = Colorize.escape_codes(prematch).first
      reset = Colorize.escape_codes(postmatch).first
      highlighted_term = Colorize::Background.cyan(term)
      if start and reset
        reset + highlighted_term + start
      else
        highlighted_term
      end
    end
    id         = Colorize::Text.cyan        tweet[:id]
    user_name  = Colorize::Text.red         tweet[:user_name]
    puts "#{created_at}\t#{c_text}\t#{id}\t#{user_name}\n\n"
  end
end
