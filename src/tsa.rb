#!/bin/ruby -W0
# coding: utf-8
 
require 'twitter'

#-------------------------------------------------------
# Global
#-------------------------------------------------------
ckey     = "YOUR_CONSUMER_KEY in tsa.sec"
csecret  = "YOUR_CONSUMER_SECRET in tsa.sec"
atoken   = "YOUR_ACCESS_TOKEN in tsa.sec"
atsecret = "YOUR_ACCESS_SECRET in tsa.sec"

#-------------------------------------------------------
# Main
#-------------------------------------------------------
hfile = open( "tsa.sec" )
hfile.each_line{ |line|
  
  next if /^\s*$/ =~ line

  words = line.chomp.split(/\s+/)

  if words.size >= 3
    if words[0] == "Consumer"
      if words[1] == "key"
        ckey     = words[2]
      elsif words[1] == "secret"
        csecret  = words[2]        
      end
    elsif words[0] == "Access" && words[1] == "token"
      if words[2] == "secret"
        atsecret = words[3]
      else
        atoken   = words[2]        
      end      
    end
  end
  
}

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ckey    
  config.consumer_secret     = csecret 
  config.access_token        = atoken  
  config.access_token_secret = atsecret
end

tweets = client.user_timeline( "iprettygetter" )

tweets.each{ |tweet|
  p tweet.text
  p tweet.created_at
}
