root = File.expand_path('..', File.dirname(__FILE__))
require File.join(root, 'app')
require 'colorize'
require 'English'
class App::Report
  include Enumerable
  StoredTweet = ::Struct.new(:tweet) do
    attr_accessor :score
    def parent
      tweet[:parent]
    end
    %w[
      id
      uri
      full_text
      favorited?
      in_reply_to_screen_name
      in_reply_to_tweet_id
      in_reply_to_user_id
      lang
      retweet_count
      retweeted?
      created_at
      uris
      media
      hashtags
      attrs
      full_text_urls
      dump
      user_id
      user_name
    ].map(&:intern).each do |attr|
      define_method(attr) do tweet[attr] end
    end
    def text
      attrs[:text]
    end
    def favorite_count
      attrs[:favorite_count]
    end
    def retweeted_status
      attrs[:retweeted_status]
    end
    def user_followers_count
      user_attrs[:followers_count]
    end
    def user_friends_count
      user_attrs[:friends_count]
    end
    def user_friends_count
      user_attrs[:friends_count]
    end
    def user_listed_count
      user_attrs[:listed_count]
    end
    def user_statuses_count
      user_attrs[:statuses_count]
    end
    private
    def attrs
      @attrs ||= begin
                   attrs = tweet[:attrs]
                   case attrs
                   when String
                     eval(attrs)
                   when NilClass
                     require 'pp'
                     p score
                     pp tweet
                     fail "nil attrs? #{tweet.keys.inspect}"
                   else
                     attrs
                   end
                 end
    end
    def entities
      @entities ||= attrs[:entities]
    end
    def user_attrs
      @user_attrs ||= attrs[:user]
    end
  end

  def initialize(store,io=STDOUT)
    @store = store
    @io = io
  end

  def io=(io)
    @io = io
  end

  def puts(msg='')
    @io.puts(msg << "\n")
  end

  def print
    each do |tweet|
      self.class.print_tweet(tweet, @io)
    end
  end

  def self.print_tweet(tweet, io=STDOUT)
    io.puts
    io.puts %w(full_text user created_at id).map(&:intern).
      map{|attr| tweet.send(attr) }.
      join("\n\t")
    io.puts
  end

  def self.pretty_print_tweet(tweet, pattern, io=STDOUT)
    # report.print_tweet(tweet)
    created_at = Colorize::Text.green       tweet.created_at
    c_text = Colorize::Text.yellow(tweet.full_text)
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
    id         = Colorize::Text.cyan        tweet.id
    user_name  = Colorize::Text.red         tweet.user_name
    yield if block_given?
    if score = tweet.score
      score = Colorize::Text.white "Score: #{score}"
    end
    io.puts "#{score}  #{created_at}\t#{c_text}\t#{id}\t#{user_name}\n\n"
  end

  def recommended
    select do |tweet|
      score = 0
      retweet_count = tweet.retweet_count.to_i
      unless retweet_count.zero?
        retweet_score = (Math.exp(retweet_count) % retweet_count)
        score += retweet_score.ceil unless retweet_score.nan?
      end
      score += 3 if tweet.in_reply_to_tweet_id
      score += 4 if tweet.favorited?
      tweet.score = score
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
      tweet.full_text =~ pattern
    end
  end

  def each
    @store.read do |store|
      store.roots.each do |key|
        tweet = store[key].dup
        if reply_tweet_id = tweet[:in_reply_to_tweet_id]
          if parent  = store[reply_tweet_id]
            tweet.update(:parent => StoredTweet.new(parent))
          end
        end
        yield StoredTweet.new(tweet)
      end
    end
  end

end
