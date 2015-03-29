This is very alpha, but 'works for me'

## INSTALL

```sh
bundle
cp .env.sample .env
```

Edit the Twitter keys requested in the .env.  See the Twitter gem if you need help finding these.

## Features:

1. Archives tweets
2. Prints with terminal colors
3. Expands URLs in tweets
4. Reports include recommended, search by regex, and all, with Reply-to text
5. Data store is in YAML, though an adapter is available.
6. Data store can be regularly pared down

## Usage

Preferably in a screen or tmux session

```sh
ruby loop.rb
```

This will

1. Run an import of most recent tweets in a forked process (to managed memory leaks)
2. Pare down the tweet archive when it reaches the threshold number of tweets
3. Repeat every 30 minutes

See the `loop.rb` file for how it's being invoked.

```sh
./recs.sh
```

Is in example script that runs the recommended tweet report `ruby report.rb 'recommended' | less`

A 'favs.sh' script may be, e.g. `ruby report.rb 'ruby|rbx|rubinius|rails' | less`

## Color

On my Mac OSX (Mavricks), I can get ANSI codes read in as color in less by typing `-R`

I also use `brew install source-highlight`

In my ~/.profile I have

```bashrc
# Like less but outputs colors instead of raw ansi escape codes
# brew install source-highlight
export LESSOPEN="| `brew --prefix`/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '
export LESSCHARSET=utf-8 # don't print out unicode as e.g. <E2><80><99>
# alias vless='vim -u /usr/share/vim/vim71/macros/less.vim'
# https://superuser.com/questions/71588/how-to-syntax-highlight-via-less
# function cless () {
#     pygmentize -f terminal "$1" | less -R
# }
# alias vless="/Applications/MacVim.app/Contents/Resources/vim/runtime/macros/less.sh"
```


## TODO:

* search across various tweet slices (for dates)

## Reference

```plain
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
```

```ruby
http://rdoc.info/gems/twitter/Twitter/Tweet
class TweetEntity
  :id
  :uri, :full_text, :favorited?
  :in_reply_to_tweet_id
  :in_reply_to_user_id
  :in_reply_to_screen_name
  :lang
  :retweet_count
  :retweeted?
  :created_at
  :uris
  :hashtags
  :attrs
  :user.id/name
end
# :attrs:
#   :text: ! '@steveklabnik Ewwwww'
#   :source: <a href="https://about.twitter.com/products/tweetdeck" rel="nofollow">TweetDeck</a>
#   :truncated: false
#   :in_reply_to_status_id: 476416785617805312
#   :in_reply_to_user_id: 22386062
#   :in_reply_to_screen_name: steveklabnik
#   :geo:
#   :coordinates:
#   :place:
#   :contributors:
#   :retweet_count: 0
#   :favorite_count: 0
#   :entities:
#     :hashtags: []
#     :symbols: []
#     :urls: &70312086735720 []
#     :user_mentions:
#     - :screen_name: steveklabnik
#       :name: Brooklyn.rs
#       :id: 22386062
#       :id_str: '22386062'
#       :indices:
#       - 0
#       - 13
#   :favorited?: false
#   :retweeted?: false
#   :lang: und
#   :user:
#     :id: 12503922
#     :name: BoÐil Stokke
#     :screen_name: bodil
#     :location: London
#     :description: Computer Science. Church of Emacs. Thought leader @FutureAdLabs.
#       @web_rebels organiser. Pirate. Angry feminist retweeter. @dogecoin millionaire.
#       Team Pinkie.
#     :url: http://t.co/27pQVswdrv
#     :entities:
#       :url:
#         :urls:
#         - :url: http://t.co/27pQVswdrv
#           :expanded_url: http://bodil.org/
#           :display_url: bodil.org
#           :indices:
#           - 0
#           - 22
#       :description:
#         :urls: []
#     :protected: false
#     :followers_count: 6693
#     :friends_count: 851
#     :listed_count: 311
#     :created_at: Mon Jan 21 18:41:24 +0000 2008
#     :favourites_count: 820
#     :utc_offset: 3600
#     :time_zone: London
#     :geo_enabled: true
#     :verified: false
#     :statuses_count: 15108
#     :lang: en
#     :contributors_enabled: false
#     :is_translator: false
#     :is_translation_enabled: false
#     :profile_background_color: '131516'
#     :profile_background_image_url: http://pbs.twimg.com/profile_background_images/676775741/be2b8939ea2941d6676af93e30f011c8.jpeg
#     :profile_background_image_url_https: https://pbs.twimg.com/profile_background_images/676775741/be2b8939ea2941d6676af93e30f011c8.jpeg
#     :profile_background_tile: false
#     :profile_image_url: http://pbs.twimg.com/profile_images/378800000563736483/2fdd4774f1a941cdd8cd3b51fa46271a_normal.jpeg
#     :profile_image_url_https: https://pbs.twimg.com/profile_images/378800000563736483/2fdd4774f1a941cdd8cd3b51fa46271a_normal.jpeg
#     :profile_banner_url: https://pbs.twimg.com/profile_banners/12503922/1398767594
#     :profile_link_color: 30325C
#     :profile_sidebar_border_color: FFFFFF
#     :profile_sidebar_fill_color: EFEFEF
#     :profile_text_color: '333333'
#     :profile_use_background_image: true
#     :default_profile: false
#     :default_profile_image: false
#     :following: true
#     :follow_request_sent: false
#     :notifications: false

eval(tweet[:attrs]).each_pair do |k, v|
  case k
  when :entities then p v[:urls]
  when :retweeted_status then p v[:entities][:urls]
  when :user then p v.keys.grep(/_count/).map{|c| [c, v[c]]}
    # [[:followers_count, 12923], [:friends_count, 544], [:listed_count, 1029], [:favourites_count, 146], [:statuses_count, 25044]]
  else

  end
end
```



## LICENSE

MIT, by Benjamin Fleischer, 2014-Present
