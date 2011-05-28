require 'base64'
require 'digest/md5'

class Skeet < Sinatra::Base
  configure do
    IMGKit.configure do |config|
      config.wkhtmltoimage = File.join(File.dirname(__FILE__), 'bin', 'wkhtmltoimage-amd64')
      # config.wkhtmltoimage = File.join(File.dirname(__FILE__), 'bin', 'wkhtmltoimage')
      config.default_options = {
        quality: 75
      }
    end
    
    set :cache, Dalli::Client.new
  end
  
  get '/' do
    headers({
      'Content-Disposition' => 'inline',
      'Content-Type' => 'image/jpeg'
    })
    
    cached_image = settings.cache.get(cache_key)
    
    unless cached_image
      image = IMGKit.new(params[:url]).to_img
      settings.cache.set(cache_key, Base64.encode64(image))
    else
      image = Base64.decode64(cached_image)
    end

    image
  end
  
  get '/cache-stats' do
    settings.cache.stats.to_s
  end
  
  private
  def cache_key
    Digest::MD5.hexdigest(params[:url])
  end
end