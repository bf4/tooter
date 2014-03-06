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

  def recommended
    select do |tweet|
      score = 0
      if retweet_count = tweet[:retweet_count].to_i
        unless retweet_count.zero?
          retweet_score = (Math.exp(retweet_count) % retweet_count)
          score += retweet_score.ceil unless retweet_score.nan?
        end
      end
      score += 3 if tweet[:in_reply_to_tweet_id]
      score += 4 if tweet[:favorited]
      tweet[:score] = score
      score >= 7
    end
  end

  # TODO: add result limit and ordering
  # e.g. 200 most-recent
  def search(term)
    # pattern = Regexp.new(pattern, case_insensitive=true)
    # pattern = Regexp.new(pattern, Regexp::EXTENDED | Regexp::IGNORECASE)
    # pattern = Regexp.new(pattern)
    pattern = Regexp.new(term)
    select do |tweet|
      tweet[:full_text] =~ pattern
    end
  end

      # :in_reply_to_screen_name => tweet.in_reply_to_screen_name,
      # :in_reply_to_tweet_id    => tweet.in_reply_to_tweet_id,
      # :in_reply_to_user_id     => tweet.in_reply_to_user_id,
  def each
    @store.read do |store|
      store.roots.each do |key|
        tweet = store[key].dup
        if reply_tweet_id = tweet[:in_reply_to_tweet_id]
          tweet.update(:parent => store[reply_tweet_id])
        end
        yield tweet
      end
    end
  end

end

if $0 == __FILE__
  filename = App.root.join('tweets').to_s
  store = Store.new(filename)
  report = App::Report.new(store)

  # results = report.recommended
  # pattern = nil
  #
  pattern = ARGV[0] # 'noelrap|kerrizor|dhh|danmayer'
  if pattern.to_s.size > 0
    results = report.search(pattern)
  else
    results = report.map.to_a
  end
  # test_results = [
  #   {
  #     :created_at => 'some time',
  #     :full_text  => 'something with ruby in it',
  #     :id         => '5',
  #     :user_name  => 'schmo',

  #   }
  # ]
  def print_tweet(tweet, pattern)
    # report.print_tweet(tweet)
    created_at = Colorize::Text.green       tweet[:created_at]
    c_text = Colorize::Text.yellow(tweet[:full_text])
    c_text = c_text.gsub(Regexp.new(pattern)) do
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
    end if pattern
    id         = Colorize::Text.cyan        tweet[:id]
    user_name  = Colorize::Text.red         tweet[:user_name]
    yield if block_given?
    if score = tweet[:score]
      score = Colorize::Text.white "Score: #{score}"
    end
    puts "#{score}  #{created_at}\t#{c_text}\t#{id}\t#{user_name}\n\n"
  end
  results.each do |tweet|
    print_tweet(tweet, pattern) do
      if parent = tweet[:parent]
        puts "\tReplyTo: #{parent[:full_text]}\t#{parent[:user_name]}\n"
      end
    end
  end
end
