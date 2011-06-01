#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-sqlite-adapter'

### Config

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/trapper.sqlite3")


### Models

class Trap
  include DataMapper::Resource

  property :id,          Serial
  property :url,         String
  property :name,        String
  property :description, Text
  property :created_at,  DateTime
  property :updated_at,  DateTime
end

DataMapper.auto_upgrade!


### Controllers

get '/' do
  haml :index
end

get '/new' do
  haml :new
end

post '/new' do
  @trap = Trap.new
  @trap.attributes = params[:trap]
  if @trap.save
    redirect "/#{@trap.id}"
  else
    redirect "/"
  end
end

# allow both /search and /s
# add words with + (/s/ruby+rails)
get %r{/s(earch)?/([\w\d+]+)} do
  term = params[:captures][1]
  @found = Hash.new
  ['url', 'name', 'description'].each do |type|
    search = ":#{type}.like => '%#{term}%'"
    @found[type] = Trap.all(search)
  end
  if @found.size > 0
    haml :search
  else
    redirect '/'
  end
end

get '/:id' do
  @trap = Trap.get(params[:id])
  if @trap
    haml :show
  else
    redirect '/'
  end
end
