require File.expand_path '../boot', __FILE__
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_resource/railtie'
require "sprockets/railtie"
Bundler.require *Rails.groups(:assets => %w(development test)) if defined? Bundler
module NovelsOnLocation
  class Application < Rails::Application
    config.assets.enabled = true
    config.assets.initialize_on_precompile = false
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.middleware.insert_before(Rack::Lock, Rack::Rewrite) do
      r301 '/locations/shermans-march-the-first-full-length...', '/locations/shermans-march-the-first-full-length-narrative-of-general-william-t-shermans-devastating-march-through-georgia-and-the-carolinas'
    end
  end
end