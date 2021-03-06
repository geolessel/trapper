#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-sqlite-adapter'
require 'haml'
require 'sass'

### Config

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/trapper.sqlite3")


### Models

class Site
  include DataMapper::Resource

  property :id,          Serial
  property :url,         String
  property :name,        String
  property :description, Text
  property :created_at,  DateTime
  property :updated_at,  DateTime

  default_scope(:default).update(:order => [:created_at.desc])
  has n, :tags, :through => Resource

  def update_tags(new_tags_array)
    new_tags = Array.new
    new_tags_array.each do |t|
      if nt = Tag.first(:name => t)
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

  has n, :sites, :through => Resource
end

DataMapper.auto_upgrade!


### Controllers

get '/' do
  @sites = Site.all
  haml :index
end

get '/new' do
  @site = Site.new
  @page_title = "New"
  haml :new
end

post '/new' do
  @site = Site.new
  @site.attributes = params[:site]
  if @site.update_tags(params[:tags].split(/\s/)) && @site.save
    redirect "/#{@site.id}"
  else
    redirect "/"
  end
end

get '/save?*' do
  @site = Site.new
  @site.url = params[:url]
  @site.name = params[:title]
  @site.description = params[:notes]
  haml :save
end

post '/save' do
  @site = Site.new
  @site.attributes = params[:site]
  if @site.update_tags(params[:tags].split(/\s/)) && @site.save
    redirect "/#{@site.id}"
  else
    redirect "/"
  end
end

# allow both /search and /s
# add words with '+' (/s/ruby+rails)
get %r{/s(earch)?/(.+)} do
  terms = params[:captures][1].split(/\s/) # The + character is subbed by space for some reason
  @found = Hash.new
  ['url', 'name', 'description'].each do |type|
    collection = Site.all(eval(":#{type}").like => {"%?", terms[0]})
    1.upto terms.size-1 do |i|
      collection = collection & Site.all(eval(":#{type}").like => {"%?", terms[i]})
    end
    @found[type] = collection
  end
  if @found.size > 0
    @page_title = "#{terms.join(", ")} > Search"
    haml :search
  else
    redirect '/'
  end
end

# allow /tags /tag and /t
# add tags with '+'
get %r{/t(ags?)?/(.+)} do
  @found = Array.new
  @tags = Array.new
  params[:captures][1].split(/\s/).each do |tag|
    if t = Tag.first(:name.like => tag)
      @tags << t.name
      @found = @found.empty? ? t.sites : @found & t.sites
      @found.flatten!
    end
  end
  @found.uniq!

  @page_title = "#{@tags.join(", ")} > Tags"
  haml :tags
end

get '/:id/edit' do
  @site = Site.get(params[:id])
  if @site
    @page_title = "#{@site.name} > Edit"
    haml :edit
  else
    redirect '/'
  end
end

post '/:id/edit' do
  @site = Site.get(params[:id])
  @site.attributes = params[:site]
  if @site.update_tags(params[:tags].split(/\s/)) && @site.save
    redirect "/#{@site.id}"
  else
    redirect "/#{@site.id}/edit"
  end
end

get '/css/style.css' do
  scss :style
end

get '/:id' do
  @site = Site.get(params[:id])
  if @site
    @page_title = "#{@site.name} > Site"
    haml :show
  else
    redirect '/'
  end
end
