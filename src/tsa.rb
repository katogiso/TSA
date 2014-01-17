#!/bin/ruby -W0
# coding: utf-8
 
require 'twitter'
require 'date'

#-------------------------------------------------------
# Global
#-------------------------------------------------------
ckey     = "YOUR_CONSUMER_KEY in tsa.sec"
csecret  = "YOUR_CONSUMER_SECRET in tsa.sec"
atoken   = "YOUR_ACCESS_TOKEN in tsa.sec"
atsecret = "YOUR_ACCESS_SECRET in tsa.sec"

flag_week = true

#-------------------------------------------------------
# Local methods
#-------------------------------------------------------
def parseKeyFile(name)
  keys = {
    "ckey"     => "",
    "csecret"  => "",
    "atoken"   => "",
    "atsecret" => ""
  }
  
  hfile = open( name )
  hfile.each_line{ |line|
    
    next if /^\s*$/ =~ line
    
    words = line.chomp.split(/\s+/)
  
    if words.size >= 3
      if words[0] == "Consumer"
        if words[1] == "key"
          keys["ckey"]     = words[2]
        elsif words[1] == "secret"
          keys["csecret"]  = words[2]        
        end
      elsif words[0] == "Access" && words[1] == "token"
        if words[2] == "secret"
          keys["atsecret"] = words[3]
        else
          keys["atoken"]   = words[2]        
        end      
      end
    end
  }
  return keys
end
#-------------------------------------------------------
# Main
#-------------------------------------------------------

# Setup the twitter object
keys = parseKeyFile("tsa.sec")
client = Twitter::REST::Client.new do |config|
  config.consumer_key        = keys["ckey"]    
  config.consumer_secret     = keys["csecret"]     
  config.access_token        = keys["atoken"]      
  config.access_token_secret = keys["atsecret"]    
end

#get the tweets
tweets = client.user_timeline( "iprettygetter", {:count => 200, :max_id => 423044343243345921} )

#
if flag_week 
  p tweets.size
  tweets.each{ |tweet|
    if /.*【(.*)】.*出勤.*/ =~ tweet.text
      weekday     = tweet.created_at.wday
      person_name = tweet.text.gsub(/.*【(.*)】.*出勤.*/, '\1' )
      
      if /まゆみ/ =~ person_name 
        printf( "%s <> %s <> %s <> %s\n",  weekday,  person_name, tweet.created_at, tweet.id )
      end
    end
  }
end
