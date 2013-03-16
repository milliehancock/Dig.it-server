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
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/adserver.db")
#this could also be done in a .yml file, where the development and production paths and filenames are different. this makes it easy to specify different database settings for different environments

########################################
#              Classes                 #
######################################## 
class Ad
	
	include DataMapper::Resource
	
	property :id,			Serial
	property :title,		String
	property :content,		Text
	property :width,		Integer
	property :height,		Integer
	property :filename,		String
	property :url,			String
	property :is_active,	Boolean
	property :created_at,	DateTime
	property :size,			Integer
	property :content_type,	String
	
	#Steve, is this how I talk back and forth between classes?
	has n, :clicks
	
	#this is a model, rather than a handler....
	def handle_upload( file )
		self.content_type = file[:type]
		self.size = File.size(file[:tempfile])
		path = File.join(Dir.pwd, "/public/ads", self.filename)
		File.open(path, "wb") do |f|
			f.write(file[:tempfile].read)
		end
	end

end	

class Click
	
	include DataMapper::Resource
	
	property :id,			Serial
	property :ip_address,	String
	property :created_at,	DateTime
	
	#Steve, is this how I talk back and forth between classes?
	belongs_to :ad


end	
	
########################################
#        Routes and handlers           #
######################################## 
        
#this specifies a 'development' mode, rather than a 'production' one
configure :development do
	# Create or upgrade all tables at once
	#DO NOT use auto_migrate, it will wipe your database.
	DataMapper .auto_upgrade!
end

#this is part of the authorization process; using a helper keeps the namespace clean??
helpers do
	include Sinatra::Authorization
end

#set utf-8 for outgoing
before do
	headers "Content-Type" => "text/html; charset=utf-8"
end

#handler for main page
get '/' do
	@title = "Welcome to the PeepCode AdServer!"
	erb :welcome
end

#display an ad somehow
get '/ad' do	
	#pick a random ad (this is a little tricky with DataMapper, so we'll write a query)
	id = repository(:default).adapter.query(
		'SELECT id FROM ads ORDER BY random() LIMIT 1;'
	)
	@ad = Ad.get(id)
	#process the ad template; tell it to not use the main.css styling
	erb :ad, :layout => false
end

#show a list of ads
get '/list' do
	require_admin
	@title = "List Ads"
	#lget all the ads and display them in descending order
	@ads = Ad.all(:order => [:created_at.desc])
	#process the list template
	erb :list
end

#collect the content for 'ads'
get '/new' do
	require_admin
	@title = "Create a New Ad"
	erb :new
end

#delete ads
get '/delete/:id' do
	require_admin
	#load the ad specified by the id in the parameters
	ad = Ad.get(params[:id])
	#unless it's empty...
	unless ad.nil?
		#check the file path
		path = File.join(Dir.pwd, "/public/ads", ad.filename)
		#delete the file
		File.delete(path)
		#delete the ad itself
		ad.destroy
	end
	#then, we'll go back to 'list'
	redirect('/list')
end

#take content from /new and create an ad post
post '/create' do
	require_admin
	#make a new instance of the ad class
	@ad = Ad.new(params[:ad])
	@ad.handle_upload(params[:image])
	if @ad.save
		#redirect to show the id of the ad
		redirect "/show/#{@ad.id}"
	else
		#otherwise, show a list of all of the other ads. this indicates that there was a problem
		redirect('/list')
	end
end

#show details of ad
get '/show/:id' do
	require_admin
	#the 'get' function is from DataMapper
	@ad = Ad.get(params[:id])
	if @ad
		#if it exists, process the show.erb template file
		erb :show
	else
		#otherwise, redirect back to /list
		redirect('/list')
	end
end

#track clicks
get '/click/:id' do
	#look up the ad based on that id
	ad = Ad.get(params[:id])
	#grab the remote address from the environment array
	ad.clicks.create(:ip_address => env["REMOTE_ADDR"])
	#redirect to the url from the ad
	redirect(ad.url)
end
