require 'base64'
require 'digest/md5'

class Skeet < Sinatra::Base
  configure do
    IMGKit.configure do |config|
      config.wkhtmltoimage = File.join(File.dirname(__FILE__), 'bin', 'wkhtmltoimage-amd64')
      # config.wkhtmltoimage = File.join(File.dirname(__FILE__), 'bin', 'wkhtmltoimage')
      config.default_options = { quality: 100 }
    end
    
    set :cache, Dalli::Client.new
    set :max_image_width, 300
  end
  
  get '/*' do
    expires 1600
    halt unless valid_uri?(params[:splat].join)

    headers({
      'Content-Disposition' => 'inline',
      'Content-Type' => 'image/jpeg'
    })
    
    cached_image = settings.cache.get(cache_key)
    
    if cached_image
      image = Base64.decode64(cached_image)
    else
      image = IMGKit.new(params[:splat].join).to_img
      resize = Magick::Image.from_blob(image).first.change_geometry("#{dimension}x") do |cols, rows, img|
        img.resize!(cols, rows)
      end
      
      image = resize.to_blob
      
      settings.cache.set(cache_key, Base64.encode64(image))
    end

    image
  end
  
  get '/cache-stats' do
    settings.cache.stats.to_s
  end
  
  private
  def dimension
    dimension = params[:dimension] || settings.max_image_width
    return settings.max_image_width if dimension.to_i > settings.max_image_width
    
    dimension
  end
  
  def cache_key
    Digest::MD5.hexdigest(params[:splat].join)
  end
  
  def valid_uri?(uri)
    uri.match(/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix)
  end
end