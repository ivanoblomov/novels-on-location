require File.expand_path '../boot', __FILE__
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'
Bundler.require *Rails.groups(assets: %w(development test)) if defined? Bundler
module NovelsOnLocation
  class Application < Rails::Application
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
    }
    config.assets.enabled = true
    config.assets.initialize_on_precompile = false
    config.encoding = 'utf-8'
    config.filter_parameters += [:password]
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 '/locations/fiesta-arrow-classic-2', '/locations/fiesta-arrow-classic-1'
      r301 '/locations/ice-drift-1', '/locations/ice-drift'
      r301 '/locations/la-famiglia-moskat-1', '/locations/la-famiglia-moskat'
      r301 '/locations/la-famiglia-moskat-2', '/locations/la-famiglia-moskat'
      r301 '/locations/plastiki-across-the-pacific-on-plastic-an-adventure-to-save-our-oceans-1', '/locations/plastiki-across-the-pacific-on-plastic-an-adventure-to-save-our-oceans'
      r301 '/locations/shermans-march-the-first-full-length...', '/locations/shermans-march-the-first-full-length-narrative-of-general-william-t-shermans-devastating-march-through-georgia-and-the-carolinas'
      r301 '/locations/the-adventures-of-tom-sawyer-1', '/locations/the-adventures-of-tom-sawyer'
    end
  end
end
