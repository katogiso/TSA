#!/bin/ruby -W0
# coding: utf-8
 
require 'twitter'
require 'time'
require 'sqlite3'
require 'pp'

#-------------------------------------------------------
# Global
#-------------------------------------------------------

stop_year     = 2012
numOfMaxRetry = 100

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

def getTweets( client, userid, tweetid )
  tweet = Array.new
  if tweetid == 0
    tweet = client.user_timeline( userid, {:count => 200 } )
  else
    tweet = client.user_timeline( userid, {:count => 200, :max_id => tweetid} )
  end
  return tweet
end

def getDatabase( userid ) 
  return SQLite3::Database.new("TSA."+userid+".sqlite3") 
end

def makeDatabaseTable( database )
  
  sql = <<-SQL
  SELECT COUNT(*)
  FROM sqlite_master
  WHERE type='table' AND name='tweet_table'
  SQL
  
  
  if database.execute( sql ) == "" 
    sql = <<-SQL
    CREATE TABLE tweet_table (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      name     TEXT NOT NULL,
      date     TEXT NOT NULL,
      tweetid  INTEGER NOT NULL UNIQUE,
      tweet    TEXT NOT NULL
    );
    SQL
    
    database.execute( sql )    
  end
  
end

def addDataToDatabase( database, hdata )
  
  sql = <<-SQL
  INSERT INTO tweet_table ( name,
                            date,
                            tweetid,
                            tweet )
              VALUES      (
                            ?,
                            ?,
                            ?,
                            ?
                          );
  SQL

  database.execute( sql, hdata )
  
end

def getMinTweetID( database )

  sql = <<-SQL
  SELECT MIN( tweetid ) FROM tweet_table 
  SQL

  text = nil
  database.execute( sql ){ |row|
    text = row
  }

  if text == nil
    text = [0]
  end
  
  return text[0]
end

def getMinTweetYear( database )

  sql = <<-SQL
  SELECT MIN( date ) FROM tweet_table 
  SQL

  text = ""
  database.execute( sql ){ |row|
    text = row
  }

  return Time.parse( text[0] ).year
end

def hasTweetID?( database, tweetid )

  sql = <<-SQL
  SELECT * FROM tweet_table WHERE tweetid == #{tweetid};
  SQL
  
  return ( database.execute( sql ).size > 0 )? true : false
end

def addTweets( database, tweets )
  printf( "Add the tweets to the data base.\n" )
  database.execute( "BEGIN TRANSACTION" )
  tweets.each { |tweet|
    if /.*【(.*)】.*出勤.*/ =~ tweet.text
      name    = tweet.text.gsub(/.*【(.*)】.*出勤.*/, '\1' )
      date    = tweet.created_at.to_s
      tweetid = tweet.id
      tweet   = tweet.text
      
      if not hasTweetID?( database, tweetid ) 
        addDataToDatabase( database, [name,date,tweetid,tweet] )
      end
    end
  }
  database.execute( "COMMIT TRANSACTION" )
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

#Get the tweets
userid = "iprettygetter"

#
database = getDatabase( userid )
makeDatabaseTable( database )
database.close

numOfRetry = 0
begin
  year = Time.now.year
  while year > stop_year and numOfRetry < numOfMaxRetry
    
    database = getDatabase( userid )
    printf( "Getting tweet now (%d) %d times id= %d\n", year, numOfRetry, getMinTweetID( database ))
    tweets = getTweets( client, userid, getMinTweetID( database ))
    addTweets( database, tweets )
    database.close
    
    database = getDatabase( userid )    
    year     = getMinTweetYear( database )
    database.close
    
    numOfRetry += 1
    sleep(60)
  end
rescue => errCode
   p "[Resque]"
   p errCode
   p getMinTweetYear( database )
   p ""
end

printf( "Done!\n" )



