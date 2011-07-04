# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
NovelsOnLocation::Application.initialize!

NovelsOnLocation::Application.configure do
  config.amazon_access_key_id = 'AKIAINFSZKSQ4ZTKFDZA'
  config.amazon_secret_access_key = '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'
  config.facebook_app_id = '216729245030640'
  config.production_mongohq_db = 'app540417'
  config.production_mongohq_password = 'uqdb1uz5eqdrjmyrfi9okc'
  config.production_mongohq_port = '27107'
end
