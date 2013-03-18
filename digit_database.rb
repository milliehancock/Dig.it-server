########################################
#           Gems and stuff             #
######################################## 

# what does 'sudo gem install --no-rdoc --no-ri' mean in the terminal?
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-sqlite-adapter'
require 'data_mapper'
require 'lib/authorization'

#telling DataMapper how to talk to the database
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/digit_database.db")
#this could also be done in a .yml file, where the development and production paths and filenames are different. this makes it easy to specify different database settings for different environments

########################################
#              Classes                 #
######################################## 
class User
	
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	property :created_at,	DateTime
	
	#Users have mixes
	has n, :mixes
	
	

end	

class Mix
	
	include DataMapper::Resource
	
	property :id,			Serial
	property :name,			String
	property :description,	String
	property :created_at,	DateTime
	
	#Mixes belong to users
	belongs_to :user
	
	#Mixes have tracks
	has n, :tracks
	

end	

class Track
	
	include DataMapper::Resource
	
	property :id,			Serial
	#tracks have a location
	property :lat,			String
	property :lon,			String
	#tracks have a song name, song URL, song identifier <-- these are things you figure out with Spotify or whatever
	#if i'm using spotify, i may just need the URL
	property :songURL,		String
	#if I'm not using a streaming service, I would need all of that song info
	property :name,			String
	property :artist,		String
	property :trackLength,	String #????	
	#tracks need to have an order
	property :trackOrder,	Integer
	property :created_at,	DateTime
	
	#Tracks belong to mixes
	belongs_to :mix

end	

DataMapper.finalize

########################################
#        Routes and handlers           #
######################################## 
        
#this specifies a 'development' mode, rather than a 'production' one
configure :development do
	# Create or upgrade all tables at once
	#DO NOT use auto_migrate, it will wipe your database.
	DataMapper.auto_upgrade!
end

#set utf-8 for outgoing
before do
	headers "Content-Type" => "text/html; charset=utf-8"
end



