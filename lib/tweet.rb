# coding: utf-8
require 'delegate'
require_relative 'expand_url'
# https://gist.github.com/bf4/5541450#file-expand_url-rb
# https://github.com/rubyrogues/rubyfriends/pull/43/files
# http://devblog.avdi.org/2012/01/31/decoration-is-best-except-when-it-isnt/
require_relative 'colorize'
class App::Tweet < SimpleDelegator
  ExpandUrl = ::ExpandUrl
  # from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
  #      https://gist.github.com/gruber/249502
  #      https://gist.github.com/gruber/8891611
  URI_REGEX = %r{(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}
  def full_text
    process_text(super)
  end
  def process_text(text)
    # make links anchors
    text = text.gsub(URI_REGEX) do |url|
      expand_url(url)
    end
    # # link hashtags
    # text.gsub! /#(\w+)/, '<a href="http://twitter.com/search?q=%23\\1">#\\1</a>'
    # # link users
    # text.gsub! /@(\w+)/, '<a href="http://twitter.com/\\1">@\\1</a>'
    text
  end
  def expand_url(url, retries=1)
    begin
      expanded_url = ExpandUrl.expand_url(url) do |bad_url, e|
        if retries.zero?
          debug_expansion_error(url, e)
          bad_url
        else
          expand_url(url[0..-2], 0)
        end
      end
    rescue ExpandUrl::ExpansionError => e
      debug_expansion_error(url, e)
      expanded_url = url
    end
    # %Q(<a href="#{expanded_url}" target="_blank">#{url}</a>)
    expanded_url
  end
  def debug_expansion_error(url, e = $!)
    STDERR.puts Colorize::Background.red "\n#{e.class}: failed expanding #{url.inspect}. #{e.message}"
  end
end
