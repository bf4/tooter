require 'dotenv'
Dotenv.load
require_relative 'store'
require_relative 'colorize'
# https://gist.github.com/bf4/5541450#file-expand_url-rb
# https://github.com/rubyrogues/rubyfriends/pull/43/files
# http://devblog.avdi.org/2012/01/31/decoration-is-best-except-when-it-isnt/
require 'delegate'
require_relative 'expand_url'
require 'twitter'
# Usage
# app = App.new(:rest)
# App.run
# app.print
# App.stream
class App
  Twitter = ::Twitter

  CLIENTS = {
    :rest => Twitter::REST::Client,
    :streaming => Twitter::Streaming::Client,
  }

  attr_reader :client

  def initialize(client_type=:rest)
    @client = new_client(client_type)
    filename = File.expand_path('../tweets', __FILE__)
    @store = Store.new(filename)
  end

  def handle_errors(&block)
    block.call
  rescue Twitter::Error => e
    message = %w(class message backtrace).map{|arg| "#{arg}: #{e.public_send(arg)}"}.join(", ")
    STDERR.puts message
    raise e
  end
  # https://github.com/sferik/twitter/blob/master/lib/twitter/rest/favorites.rb
  # https://github.com/sferik/twitter/blob/master/lib/twitter/rest/undocumented.rb
  # https://github.com/sferik/twitter/wiki/apps

  # http://rdoc.info/gems/twitter/Twitter/REST/Timelines#user_timeline-instance_method
  # Options Hash (options):
  #   :since_id (Integer) — Returns results with an ID greater than (that is, more recent than) the specified ID.
  #   :max_id (Integer) — Returns results with an ID less than (that is, older than) or equal to the specified ID.
  #   :count (Integer) — Specifies the number of records to retrieve. Must be less than or equal to 200.
  #   :trim_user (Boolean, String, Integer) — Each tweet returned in a timeline will include a user object with only the author's numerical ID when set to true, 't' or 1.
  #   :exclude_replies (Boolean, String, Integer) — This parameter will prevent replies from appearing in the returned timeline. Using exclude_replies with the count parameter will mean you will receive up-to count tweets - this is because the count parameter retrieves that many tweets before filtering out retweets and replies.
  #   :contributor_details (Boolean, String, Integer) — Specifies that the contributors element should be enhanced to include the screen_name of the contributor.
  #   :include_rts (Boolean, String, Integer) — Specifies that the timeline should include native retweets in addition to regular tweets. Note: If you're using the trim_user parameter in conjunction with include_rts, the retweets will no longer contain a full user object.
  def stored_ids
    @store.read {|store| store.roots }
  end
  def newest_id
    stored_ids.max
  end

  def oldest_id
    stored_ids.min
  end


  def timeline(options={})
    options = {
      :count => 200,
    }
    options.update(
      :since_id => newest_id,
    ) if newest_id
    client.home_timeline(options)
  end

  def print
    @store.read do |store|
      store.roots.each do |key|
        tweet = store[key]
        puts
        puts %w(full_text user created_at id).map(&:intern).
          map{|attr| tweet[attr] }.
          join("\n\t")
        puts
      end
    end
  end

  def self.stream
    new(:stream)
  end
  def self.run
    new(:rest).run
  end
  class Tweet < SimpleDelegator
    ExpandUrl = ::ExpandUrl
    def full_text
      process_text(super)
    end
    def process_text(text)
      # make links anchors
      text = text.gsub(/(https?[^\s]+)/o) do |url|
        begin
          expanded_url = ExpandUrl.expand_url(url) do |bad_url, e|
            debug_expansion_error(url, e)
            bad_url
          end
        rescue ExpandUrl::ExpansionError => e
          debug_expansion_error(url, e)
          expanded_url = url
        end
        # %Q(<a href="#{expanded_url}" target="_blank">#{url}</a>)
        expanded_url
      end
      # # link hashtags
      # text.gsub! /#(\w+)/, '<a href="http://twitter.com/search?q=%23\\1">#\\1</a>'
      # # link users
      # text.gsub! /@(\w+)/, '<a href="http://twitter.com/\\1">@\\1</a>'
      text
    end
    def debug_expansion_error(url, e = $!)
      STDERR.puts Colorize::Background.red "\n#{e.class}: failed expanding #{url.inspect}. #{e.message}"
    end
  end
  def run
    tweets = timeline.map do |tweet|
      tweet = Tweet.new(tweet)
      text = tweet.full_text
      created_at = Colorize::Text.green       tweet.created_at
      c_text     = Colorize::Text.yellow      text
      id         = Colorize::Text.cyan        tweet.id
      user_name  = Colorize::Text.red         tweet.user.screen_name
      puts "#{created_at}\t#{c_text}\t#{id}\t#{user_name}\n\n"
      user = tweet.user
      data = {
        :id => tweet.id,
        :uri => tweet.uri.to_s,
        :full_text => text,
        :favorited => tweet.favorited,
        :in_reply_to_screen_name => tweet.in_reply_to_screen_name,
        :in_reply_to_tweet_id    => tweet.in_reply_to_tweet_id,
        :in_reply_to_user_id     => tweet.in_reply_to_user_id,
        :lang => tweet.lang,
        :retweet_count => tweet.retweet_count,
        :retweeted => tweet.retweeted,
        :created_at => tweet.created_at,
        :uris => tweet.uris.map(&:to_s),
        :media => tweet.media,
        :hashtags => tweet.hashtags,
        :attrs    => tweet.attrs.inspect,
        :dump     => Marshal.dump(tweet),
        :user_id => user.id,
        :user_name => user.screen_name,
      }
    end
    @store.write do |store|
      tweets.each do |tweet|
      store[tweet[:id]] = store.fetch(tweet[:id], {}).
        merge(tweet) do |key, old_val, new_val|
          new_val
        end
      end
    end
  end

  # http://rdoc.info/gems/twitter/Twitter/Tweet
  # class Tweet
  #   :id
  #   :uri, :full_text, :favorited
  #   :in_reply_to_tweet_id
  #   :in_reply_to_user_id
  #   :in_reply_to_screen_name
  #   :lang
  #   :retweet_count
  #   :retweeted
  #   :created_at
  #   :uris
  #   :hashtags
  #   :attrs
  #   :user.id/name
  # end

  private

  def new_client(client_type)
    CLIENTS.fetch(client_type).new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
    end
  end
end
