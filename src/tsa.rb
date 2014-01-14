# coding: utf-8
 
require 'rubygems'
require 'net/https'
require 'twitter'
require 'oauth'
require 'json'
require 'pp'

class MyBot

 
  MY_SCREEN_NAME = "TSA"
  BOT_USER_AGENT = "my bot @#{MY_SCREEN_NAME}"
  HTTPS_CA_FILE_PATH = "./verisign.cer"  #<= ??
  
  def initialize(inFile)
    consumer_key       = ""
    consumer_secret    = ""
    access_token        = ""
    access_token_secret = ""
    
    File.open(inFile){|hf|
      hf.read{|line|
        key = line.gsub(/^.*:/,"")
        if /^Consumer-key/ =~ line
          consumer_key = key
        elsif /^Consumer-secret/ =~ line
          consumer_secret = key
        elsif /^Access-token/ =~ line
          access_token = key
        elsif /^Access-token-secret/ =~ line
          access_token_secret = key
        end
      }
    }
    @consumer = OAuth::Consumer.new(
      consumer_key,
      consumer_secret,
      :site => 'https://api.twitter.com'
    )
    @access_token = OAuth::AccessToken.new(
      @consumer,
      access_token,
      access_token_secret
    )
  end
  def connect
    uri = URI.parse("https://userstream.twitter.com/2/user.json?track=#{MY_SCREEN_NAME}")
 
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.ca_file = HTTPS_CA_FILE_PATH
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5
 
    pp https
 
    https.start do |https|
      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = BOT_USER_AGENT
      request.oauth!(https, @consumer, @access_token)
 
      buf = ""
      https.request(request) do |response|
        response.read_body do |chunk|
          buf << chunk
          while(line = buf[/.+?(\r\n)+/m]) != nil
            begin
              buf.sub!(line,"")
              line.strip!
              status = JSON.parse(line)
            rescue
              break
            end
 
            yield status
          end
        end
      end
    end
  end

  def run
    loop do
      begin
        connect do |json|
          if json['text']
            user = json['user']
            pp json['text']
            if(json['text'].match(/^@#{MY_SCREEN_NAME}/))
              @access_token.post('/1/statuses/update.json', #書きなおしたところ２
                                 'status' => "@#{MY_SCREEN_NAME} こんにちわです。",
                                 'in_reply_to_status_id' => json['id']
                                 )
              puts "success update!"
            end
          end
        end
      rescue Timeout::Error, StandardError
        puts "Twitterとの接続が切れた為、再接続します"
      end
    end
  end
  
end
