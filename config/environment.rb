require File.expand_path('../application', __FILE__)
NovelsOnLocation::Application.initialize!
NovelsOnLocation::Application.configure do
  config.admin_email = 'ed@novelsonlocation.com'
  config.amazon_access_key_id = 'AKIAINFSZKSQ4ZTKFDZA'
  config.amazon_secret_access_key = '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'
  config.facebook_app_id = '216729245030640'
end