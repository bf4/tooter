require 'delegate'
require_relative 'expand_url'
# https://gist.github.com/bf4/5541450#file-expand_url-rb
# https://github.com/rubyrogues/rubyfriends/pull/43/files
# http://devblog.avdi.org/2012/01/31/decoration-is-best-except-when-it-isnt/
require_relative 'colorize'
class App::Tweet < SimpleDelegator
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
