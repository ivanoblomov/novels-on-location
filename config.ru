# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run NovelsOnLocation::Application

use Rack::Static,
  :urls => ['/javascripts'],
  :root => 'public'

run lambda { |env|
  [
    200,
    {
      'Content-Type'  => 'text/html',
      'Cache-Control' => 'public, max-age=604800'
    }
  ]
}
