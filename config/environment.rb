# frozen_string_literal: true

require File.expand_path('application', __dir__)
NovelsOnLocation::Application.initialize!
NovelsOnLocation::Application.configure do
  config.admin_email = 'ed@novelsonlocation.com'
  config.amazon_access_key_id = ENV.fetch('AMAZON_ACCESS_KEY_ID', nil)
  config.amazon_secret_access_key = ENV.fetch('AMAZON_SECRET_ACCESS_KEY', nil)
  config.facebook_app_id = ENV.fetch('FACEBOOK_APP_ID', nil)
end
