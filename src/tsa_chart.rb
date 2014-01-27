#!/bin/ruby -W0
# coding: utf-8
 
require 'time'
require 'sqlite3'
require 'pp'
require 'erb'

#-------------------------------------------------------
# Global
#-------------------------------------------------------
userid   = "iprettygetter"
htmlname = "chart.html"
basefile = "data.base.js"

#-------------------------------------------------------
# Methods
#-------------------------------------------------------
def getDatabase( userid ) 
  return SQLite3::Database.new("TSA."+userid+".sqlite3") 
end

def getByName( database, name )
  sql = <<-SQL
  select * FROM tweet_table WHERE name="#{name}";
  SQL
  
  return database.execute( sql )
end

def closeDatabase( database )
  database.close
end

#-------------------------------------------------------
# Main
#-------------------------------------------------------

wdayTotal = Array.new(7,0)
wdayLabel = ["Sun.", "Mon.", "Tus.", "Wed.", "Thr.", "Fri.", "Sat."]
  
database = getDatabase( userid )
records  = getByName( database, "まゆみ" )
closeDatabase( database )

records.each { |record|
  wdayTotal[Date.parse(record[2]).wday] += 1
}

data  = ""
label = "\""+wdayLabel.join('","')+"\""


wdayTotal.each_with_index{ |num, i|
  data += sprintf("%d",num )
  if wdayTotal.size - 1 != i
    data += sprintf( "," )
  end
}

printf( "%s\n",data)
printf( "%s\n",label)


erb = ERB.new(File.read(basefile))

open("../html/data.js", "w"){|file|
  file.write(erb.result(binding))
}

