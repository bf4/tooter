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
