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
    encoded_image = settings.cache.get(cache_key)
    
    unless encoded_image
      image = IMGKit.new(params[:url])
      encoded_image = Base64.encode64(image.to_img)
      settings.cache.set(cache_key, encoded_image)
    end
    
    send_file(("data:image/jpeg;base64," + encoded_image), type: "application/base64", disposition: "inline")
  end
  
  get '/cache-stats' do
    settings.cache.stats.to_s
  end
  
  private
  def cache_key
    Digest::MD5.hexdigest(params[:url])
  end
end