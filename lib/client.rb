require 'store'
require 'colorize'
require 'import'
require 'report'
require 'twitter'
class App::Client

  Twitter = ::Twitter

  CLIENTS = {
    :rest => Twitter::REST::Client,
    :stream => Twitter::Streaming::Client,
  }

  attr_reader :client

  def initialize(client_type=:rest)
    @client = new_client(client_type)
    filename = App.root.join('tweets').to_s
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
    App::Report.new(@store).print
  end

  def run
    App::Import.new(@store).from_tweet_entities(timeline)
  end

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
