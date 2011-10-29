require File.expand_path('../application', __FILE__)
NovelsOnLocation::Application.initialize!
NovelsOnLocation::Application.configure do
  config.admin_email = 'admin@novelsonlocation.com'
  config.amazon_access_key_id = 'AKIAINFSZKSQ4ZTKFDZA'
  config.amazon_secret_access_key = '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'
  config.facebook_app_id = '216729245030640'
  config.production_mongohq_db = 'app1303578'
  config.production_mongohq_host = 'staff.mongohq.com'
  config.production_mongohq_password = 'f4c76d2cb1e2774d7a6f46a154aa88e8'
  config.production_mongohq_port = '10044'
end