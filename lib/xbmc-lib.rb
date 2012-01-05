require 'xbmc-client'

class XBMCLib
  def initialize(base_uri, username, password)
    Xbmc.base_uri base_uri
    Xbmc.basic_auth username, password
  end
  
  def load_api
    begin
      Xbmc.load_api!
      return true
    rescue Exception => e
      pp e
      return false
    end
  end
  
  def success(returnval = nil)
    return {:error => false, :result => returnval}
  end
  
  def failure(reason)
    return {:error => reason}
  end
  
  def pick_random_show
    shows = Xbmc::VideoLibrary.get_tv_shows
    return shows[rand(shows.size)]["tvshowid"]
  end
  
  def pick_show_named(name = :random)
    if name == :random
      return pick_random_show
    end
    
    name.strip!
    name.downcase!
    puts "Trying to find a show named #{name}"
    
    shows = Xbmc::VideoLibrary.get_tv_shows
    shows.each do |show|
      puts "checking #{show}"
      if show["label"].downcase.include? name
        puts "got a match with the show #{show['label']}"
        return show["tvshowid"]
      end
    end
    return false
  end
  
  def pick_random_episode(tvshowid)
    episodes = Xbmc::VideoLibrary.get_episodes(:tvshowid => tvshowid)
    pp episodes
    return episodes[rand(episodes.size)]["episodeid"]
  end
  
  def get_most_recent_episode
    return failure :api_failed if not load_api
    
    recently_added_episodes = Xbmc::VideoLibrary.get_recently_added_episodes
    episodeid = recently_added_episodes["episodes"][0]["episodeid"]
    episode = Xbmc::VideoLibrary.get_episode_details(:episodeid => episodeid, :properties => ["showtitle", "episode", "season"])
    return success episode
  end
  
  def play_random_episode(show = :random)
    return failure :api_failed if not load_api
    showid = pick_show_named show
    return failure :no_show_found if showid === false
    puts "Show ID: #{showid}"
    episodeid = pick_random_episode showid
    puts "Episode ID: #{episodeid}"
    episode = Xbmc::VideoLibrary.get_episode_details(:episodeid => episodeid, :properties => ["showtitle", "episode", "season"])
    pp episode
    player = Xbmc::Player.open(:item => {:episodeid => episodeid})
    pp player
    return success episode
  end
end







