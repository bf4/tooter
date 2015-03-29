require 'tweet'
require 'colorize'
class App
  class Import

    def initialize(store)
      @store = store
      @print_imported_tweets = true
    end

    def from_tweet_entities(tweet_entities)
      tweets = tweet_entities.map { |tweet_entity|
        # see https://github.com/sferik/twitter/commit/438e311d93f382960650e20898203c880ade6b25
        # https://github.com/sferik/twitter/blob/v5.14.0/lib/twitter/null_object.rb
        next if tweet_entity.nil?
        tweet_entity_to_hash(tweet_entity)
      }.compact
      save(tweets)
    end

    def tweet_entity_to_hash(tweet_entity)
      tweet = Tweet.new(tweet_entity)
      print_imported_tweet(tweet)
      user = tweet.user
      {
        :id => tweet.id,
        :uri => tweet.uri.to_s,
        :full_text => tweet.full_text,
        :favorited => tweet.favorited?,
        :in_reply_to_screen_name => tweet.in_reply_to_screen_name,
        :in_reply_to_tweet_id    => tweet.in_reply_to_tweet_id,
        :in_reply_to_user_id     => tweet.in_reply_to_user_id,
        :lang => tweet.lang,
        :retweet_count => tweet.retweet_count,
        :favorite_count => tweet.favorite_count,
        :retweeted => tweet.retweeted?,
        :created_at => tweet.created_at.iso8601,
        :uris => tweet.uris.map(&:to_s),
        :media => tweet.media,
        :hashtags => tweet.hashtags,
        :attrs    => tweet.attrs,
        :full_text_urls     => tweet.full_text_urls,
        :dump     => Marshal.dump(tweet),
        :user_id => user.id,
        :user_name => user.screen_name,
      }
    end

    def print_imported_tweet(tweet)
      return unless @print_imported_tweets
      created_at = Colorize::Text.green       tweet.created_at
      c_text     = Colorize::Text.yellow      tweet.full_text
      id         = Colorize::Text.cyan        tweet.id
      user_name  = Colorize::Text.red         tweet.user.screen_name
      puts "#{created_at}\t#{c_text}\t#{id}\t#{user_name}\n\n"
    end

    def save(tweets)
      @store.write do |store|
        tweets.each do |tweet|
          store_tweet(store, tweet)
        end
      end
    end

    def store_tweet(store, tweet)
      store[tweet[:id]] = store.fetch(tweet[:id], {}).
        merge(tweet) do |key, old_val, new_val|
        new_val
      end
    end
  end
end
