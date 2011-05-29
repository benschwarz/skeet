require 'rubygems'
require 'bundler'
Bundler.require

$:<< File.dirname(__FILE__)
require 'app'

use Rack::Head
use Rack::ConditionalGet
use Rack::Deflater
use Rack::Chunked
run Skeet