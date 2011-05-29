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
    halt unless valid_uri?(params[:url])

    headers({
      'Content-Disposition' => 'inline',
      'Content-Type' => 'image/jpeg'
    })
    
    cached_image = settings.cache.get(cache_key)
    
    unless cached_image
      image = IMGKit.new(params[:url]).to_img
      resize = Image.from_blob(image).resize_to_fit(dimension, dimension)
      
      settings.cache.set(cache_key, Base64.encode64(resize)
    else
      image = Base64.decode64(cached_image)
    end

    image
  end
  
  get '/cache-stats' do
    settings.cache.stats.to_s
  end
  
  private
  def dimension
    dimension = params[:dimension] || 300
    return 300 if dimension.to_i > 300
    
    dimension
  end
  
  def cache_key
    Digest::MD5.hexdigest(params[:url])
  end
  
  def valid_uri?(uri)
    uri.match(/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix)
  end
end