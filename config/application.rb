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
  end
end