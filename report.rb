require_relative "lib/report"
def cli_results(report, pattern)
  if pattern.to_s.size > 0
    if pattern == 'recommended'
      report.recommended
    elsif pattern == 'all'
      report.map
    else
      report.search(pattern)
    end
  else
    report.map
  end
end

# test_results = [
#   {
#     :created_at => 'some time',
#     :full_text  => 'something with ruby in it',
#     :id         => '5',
#     :user_name  => 'schmo',

#   }
# ]
FakeStore = Struct.new(:filename) do
  def read

  end
  # keys
  def roots

  end
  def [](key)

  end
end
def cli_report(filename, pattern, &block)
  filename = App.root.join(filename).to_s
  store = FakeStore.new(filename)
  report = App::Report.new(store)

  cli_results(report, pattern).each(&block)
end
def report_all(pattern = 'all', &block)
  require 'pp'
  stats = Hash.new {|hash,key| hash[key] = Hash.new {|h,k| h[k] = 0} }

  tweets_files = Dir['tweet*.yaml']
  range = (0..-1)
  tweets_files[range].each do |filename|
    puts
    puts "From #{filename}"
    cli_report(filename, pattern) do |tweet|
      stat = stats[tweet.user_id]
      stat[:count]     +=1
      stat[:favorited] +=1 if tweet.favorited?
      stat[:retweeted] +=1 if tweet.retweeted?
      stat.fetch(:user_name) { stat[:user_name] = Set.new }
      stat[:user_name] << tweet.user_name
      stat[:retweet_count] += tweet.retweet_count
      stat[:favorite_count] += tweet.favorite_count
      stat.fetch(:followers_count) { stat[:followers_count] = Set.new }
      stat[:followers_count] << tweet.user_followers_count
      stat.fetch(:friends_count) { stat[:friends_count] = Set.new }
      stat[:friends_count] << tweet.user_friends_count
      stat.fetch(:listed_count) { stat[:listed_count] = Set.new }
      stat[:listed_count] << tweet.user_listed_count
      stat.fetch(:statuses_count) { stat[:statuses_count] = Set.new }
      stat[:statuses_count] << tweet.user_statuses_count
      fail stat.inspect unless stat.is_a?(Hash)
      print '.'
    end
  end
  puts
  block.call(stats)
end
io = STDOUT
pattern = ARGV[0] # 'noelrap|kerrizor|dhh|danmayer'
file_pattern = ARGV[1] || 'tweets'
filename = file_pattern
puts "searching for #{pattern.inspect} in #{filename}"
cli_report(filename, pattern) do |tweet|
  App::Report.pretty_print_tweet(tweet, pattern, io) do
    if parent = tweet.parent
      io.puts "\tReplyTo: #{parent.full_text}\t#{parent.user_name}\n"
    end
  end
end
# report_all do |stats|
#   stats.each do |id, stat|
#     io.puts "#{id}, #{stat[:user_name].to_a.join(', ')}"
#     io.puts "\tI Favorited: #{stat[:favorited]}"
#     io.puts "\tI Retweeted: #{stat[:retweeted]}"
#     io.puts "\tRetweet Count: #{stat[:retweet_count]}"
#     io.puts "\tFavorite Count: #{stat[:favorite_count]}"
#     io.puts "\tFollowers Count: #{stat[:followers_count].to_a.max}"
#     io.puts "\tFriends Count: #{stat[:friends_count].to_a.max}"
#     io.puts "\tListed Count: #{stat[:listed_count].to_a.max}"
#     io.puts "\tStatuses Count: #{stat[:statuses_count].to_a.max}"
#     io.puts
#   end
# end
