# frozen_string_literal: true

require File.expand_path('application', __dir__)
NovelsOnLocation::Application.initialize!
NovelsOnLocation::Application.configure do
  config.admin_email = 'ed@novelsonlocation.com'
  config.facebook_app_id = ENV.fetch('FACEBOOK_APP_ID', nil)
end
