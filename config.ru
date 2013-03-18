require 'rubygems'
require 'sinatra'
require 'digit_database'

set :environment, :production

run Sinatra.application