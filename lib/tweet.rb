# coding: utf-8
require 'delegate'
require_relative 'expand_url'
# https://gist.github.com/bf4/5541450#file-expand_url-rb
# https://github.com/rubyrogues/rubyfriends/pull/43/files
# http://devblog.avdi.org/2012/01/31/decoration-is-best-except-when-it-isnt/
require_relative 'colorize'
App = Class.new unless defined?(App)
class App::Tweet < SimpleDelegator
  ExpandUrl = ::ExpandUrl
  URI_REGEX = URI::Parser.new.make_regexp(['http', 'https'])
  def full_text
    process_text(super)
  end
  def full_text_urls
    attrs[:entities][:urls]
  end
  def full_text_expanded_urls_mapping
    Hash[full_text_urls.map{|m| m.values_at(:url, :expanded_url)}]
  end
  def process_text(text)
    text = text.gsub(URI_REGEX, full_text_expanded_urls_mapping)
    text = text.gsub(URI_REGEX) do |url|
      expand_url(url)
    end
    # make links anchors
    # # link hashtags
    # text.gsub! /#(\w+)/, '<a href="http://twitter.com/search?q=%23\\1">#\\1</a>'
    # # link users
    # text.gsub! /@(\w+)/, '<a href="http://twitter.com/\\1">@\\1</a>'
    text
  end
  def expand_url(url, retries=1)
    ExpandUrl.expand_url(url) do |bad_url, e|
      if retries.zero?
        debug_expansion_error(url, e)
        bad_url
      else
        shortened_url = url[0..-2]
        expanded_url = expand_url(shortened_url, retries - 1)
        url.start_with?(expanded_url) ? url : expanded_url
      end
    end
    # %Q(<a href="#{expanded_url}" target="_blank">#{url}</a>)
  end
  def debug_expansion_error(url, e = $!)
    STDERR.puts Colorize::Background.red "\n#{e.class}: failed expanding #{url.inspect}. #{e.message}"
  end
  # from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
  #      https://gist.github.com/gruber/249502
  #      https://gist.github.com/gruber/8891611
  # also see http://tools.ietf.org/html/rfc3986#appendix-B
  # def self.uri_regex
  #   @uri_regex ||= %r{
  #     \b
  #     (                           # Capture 1: entire matched URL
  #       (?:
  #         [a-z][\w-]+:                # URL protocol and colon
  #         (?:
  #           /{1,3}                        # 1-3 slashes
  #           |                             #   or
  #           [a-z0-9%]                     # Single letter or digit or '%'
  #                                         # (Trying not to match e.g. "URI::Escape")
  #         )
  #         |                           #   or
  #         www\d{0,3}[.]               # "www.", "www1.", "www2." … "www999."
  #         |                           #   or
  #         [a-z0-9.\-]+[.][a-z]{2,4}/  # looks like domain name followed by a slash
  #       )
  #       (?:                           # One or more:
  #         [^\s()<>]+                      # Run of non-space, non-()<>
  #         |                               #   or
  #         \(([^\s()<>]+|(\([^\s()<>]+\)))*\)  # balanced parens, up to 2 levels
  #       )+
  #       (?:                           # End with:
  #         \(([^\s()<>]+|(\([^\s()<>]+\)))*\)  # balanced parens, up to 2 levels
  #         |                                   #   or
  #         [^\s`!()\[\]{};:'".,<>?«»“”‘’]      # not a space or one of these punct char
  #       )
  #     )\b
  #   }xi
  # end
end

if $0 == __FILE__
  puts App::Tweet.new({}).process_text(ARGV.join)
end
