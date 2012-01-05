require 'cora'
require 'siri_objects'
require 'pp'
require 'xbmc-lib'

#######
# Plugin for controlling XBMC via SiriProxy
# 
# This is a VERY early version and isn't really useful yet.
######

class SiriProxy::Plugin::XBMC < SiriProxy::Plugin
  def initialize(config)
    xbmc_uri = config["xbmc_uri"]
    xbmc_username = config["xbmc_username"]
    xbmc_password = config["xbmc_password"]
    @xbmc = XBMCLib.new(xbmc_uri, xbmc_username, xbmc_password)
    Xbmc.base_uri "http://192.168.0.18:8080"
    Xbmc.basic_auth "xbmc", "xbmc"
    begin
      Xbmc.load_api! # This will call JSONRPC.Introspect and create all subclasses and methods dynamically
    rescue Exception => e
      pp e
    end
    #if you have custom configuration options, process them here!
  end
  
  def check_failure(object)
    error = object[:error]
    if error === false then
      return false # No error
    else
      if error == :api_failed then say "I'm sorry, there was an error connecting to XBMC." end
      if error == :not_implemented then say "I'm sorry, that feature has not yet been implemented" end
      return true
    end
  end

  #get the user's location and display it in the logs
  #filters are still in their early stages. Their interface may be modified
  filter "SetRequestOrigin", direction: :from_iphone do |object|
    puts "[Info - User Location] lat: #{object["properties"]["latitude"]}, long: #{object["properties"]["longitude"]}"
    
    #Note about returns from filters:
    # - Return false to stop the object from being forwarded
    # - Return a Hash to substitute or update the object
    # - Return nil (or anything not a Hash or false) to have the object forwarded (along with any 
    #    modifications made to it)
  end 

  listen_for /((What is)|(what's)) my ((newest)|(latest)|(most recent(ly added)?)) ((TV )|(television ))?((show)|(episode))/i do
    episode = @xbmc.get_most_recent_episode
    if not check_failure episode then
      episode = episode[:result]
      say "Your newest TV Show is #{episode['showtitle']} season #{episode['season']} episode #{episode['episode']}: \"#{episode['label']}\"" #say something to the user!
    end
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
  listen_for /Play a random episode of (a random show|any show|anything|.*)/i do |tvshow|
    pp tvshow
    if tvshow == "a random show" or tvshow == "any show" or tvshow == "anything"
      tvshow = :random
    end
    episode = @xbmc.play_random_episode tvshow
    
    if not check_failure episode
      episode = episode[:result]
      say "Playing season #{episode['season']} episode #{episode['episode']} of #{episode['showtitle']}: \"#{episode['label']}\"" #say something to the user!
    end
    request_completed
  end

end
















