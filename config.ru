require 'rubygems'
require 'sinatra'

set :run, false
set :env, :production

FileUtils.mkdir_p 'log' unless File.exists?("log")
log = File.new("log/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

require 'trapper'
run Sinatra::Application
