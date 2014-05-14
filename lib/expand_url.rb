require 'net/http'
require 'net/https'
require 'uri'

# e.g.
# url = http://t.co/z4t0E1vArh
# ExpandUrl.expand_url(url)
# => "http://www.haaretz.com/news/national/israel-s-ag-impels-ministers-to-crack-down-on-exclusion-of-women.premium-1.519917"
module ExpandUrl
  class ExpansionError < StandardError; end
  module ExpansionErrors
    class BadUrl < ExpansionError; end
    class BadResponse < ExpansionError; end
  end
  extend self

  # raises ExpandUrl::ExpansionError
  def expand_url(url, redirects_to_follow=3, previous_url=:no_previous_url)
    request = HttpRequest.new(url, previous_url)
    return url if request.internal_redirect?
    response = request.response

    case response.code.to_i
    when 300..399
      log "url: #{url}\tresponse: #{response.inspect}"
      if redirects_to_follow.to_i > 0
        log "Following redirect"
        expand_url(response['Location'], redirects_to_follow - 1, url)
      else
        url
      end
    when 200..299
      log "url: #{url}\tresponse: #{response.inspect}"
      url
    else
      fail ExpansionErrors::BadResponse, "Can't get a good response for #{url}, got #{response.inspect}", caller
    end
  rescue ExpansionError => e
    block_given? ? yield(url, e) : raise
  end

  class HttpRequest
    require 'timeout'
    HTTP_ERRORS = [Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT,
         Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError]
    class BasicResponse < Struct.new(:url, :code, :error); end
    ExpansionErrors = ::ExpandUrl::ExpansionErrors
    CONNECT_TIMEOUT = 2

    def initialize(url, previous_url)
      @url = url
      @uri = url_to_uri(url, previous_url)
      @internal_redirect = false
    end

    def internal_redirect?
      @internal_redirect
    end

    def response
      http = Net::HTTP.new(@uri.host, @uri.port)
      if  http.use_ssl = (@uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      Timeout::timeout(CONNECT_TIMEOUT) do
        request = Net::HTTP::Get.new(@uri.request_uri)
        http.request(request)
      end
    rescue EOFError => e
      BasicResponse.new(@url, 200, e)
    rescue *HTTP_ERRORS, SocketError => e
      raise ExpansionErrors::BadResponse.new(e)
    end

    def url_to_uri(url, previous_url)
      # A URL with spaces in it is not parseable by URI()
      # URI.escape will encode spaces to %20
      # but also '#' to %23
      # Thus, URI.escape would make
      # http://t.co/53ymETE2Hd
      # http://airpa.ir/1mDCbMG
      # http://www.airpair.com/review/536abac9175a3a0200000021?utm_medium=farm-link&utm_campaign=farm-may&utm_term=ruby, ruby-on-rails and javascript&utm_source=twitter-airpair
      # into _valid_ URL
      # http://www.airpair.com/review/536abac9175a3a0200000021?utm_medium=farm-link&utm_campaign=farm-may&utm_term=ruby,%20ruby-on-rails%20and%20javascript&utm_source=twitter-airpair
      # but make
      # https://devcenter.heroku.com/articles/s3#naming-buckets
      # into the _incorrect_ URL
      # https://devcenter.heroku.com/articles/s3%23naming-buckets
      # so we're just going to escape spaces for now
      uri = URI(url.gsub(' ', '%23'))
      unless uri.respond_to?(:request_uri)
        if previous_url == :no_previous_url
          STDERR.puts "********* #{url.inspect}"
          fail URI::InvalidURIError.new(url.inspect)
        else
          @internal_redirect = true
          old_uri = URI(previous_url)
          url = "/#{url}" unless url.start_with?('/')
          new_url = "#{old_uri.scheme}://#{old_uri.host}#{url}"
          uri = URI(new_url)
        end
      end
      uri
    rescue URI::InvalidURIError, SocketError => e
      raise ExpansionErrors::BadUrl.new(e)
    end

  end

  def log(msg)
    return unless debug?
    STDOUT.puts "#{msg}\t#{caller[1]}"
  end

  def debug?
    ENV.include?('DEBUG')
  end

end
if $0 == __FILE__
  puts ExpandUrl.expand_url(ARGV[0])
end
