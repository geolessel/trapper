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

  has n, :tags, :through => Resource

  def update_tags(new_tags_array)
    new_tags = Array.new
    new_tags_array.each do |t|
      puts t
      if nt = Tag.first(:name => t)
        puts "Found tag: #{t}"
        new_tags << nt
      else
        new_tags << Tag.new(:name => t)
      end
    end
    removed_tags = self.tags - new_tags
    self.tags = new_tags
  end
end

class Tag
  include DataMapper::Resource
  
  property :id,          Serial
  property :name,        String
  property :created_at,  DateTime
  property :updated_at,  DateTime

  has n, :traps, :through => Resource
end

DataMapper.auto_upgrade!


### Controllers

get '/' do
  @sites = Trap.all
  haml :index
end

get '/new' do
  @trap = Trap.new
  haml :new
end

post '/new' do
  @trap = Trap.new
  @trap.attributes = params[:trap]
  if @trap.update_tags(params[:tags].split(/\s/)) && @trap.save
    redirect "/#{@trap.id}"
  else
    redirect "/"
  end
end

# allow both /search and /s
# add words with '+' (/s/ruby+rails)
get %r{/s(earch)?/(.+)} do
  terms = params[:captures][1].split(/\s/) # The + character is subbed by space for some reason
  puts terms
  @found = Hash.new
  ['url', 'name', 'description'].each do |type|
    collection = Trap.all(eval(":#{type}").like => "%#{terms[0]}%")
    1.upto terms.size-1 do |i|
      collection = collection & Trap.all(eval(":#{type}").like => "%#{terms[i]}%")
    end
    @found[type] = collection
  end
  if @found.size > 0
    haml :search
  else
    redirect '/'
  end
end

get '/:id/edit' do
  @trap = Trap.get(params[:id])
  if @trap
    haml :edit
  else
    redirect '/'
  end
end

post '/:id/edit' do
  @trap = Trap.get(params[:id])
  @trap.attributes = params[:trap]
  if @trap.update_tags(params[:tags].split(/\s/)) && @trap.save
    redirect "/#{@trap.id}"
  else
    redirect "/#{@trap.id}/edit"
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
