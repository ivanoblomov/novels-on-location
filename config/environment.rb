# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
NovelsOnLocation::Application.initialize!

NovelsOnLocation::Application.configure do
  config.amazon_access_key_id = 'AKIAINFSZKSQ4ZTKFDZA'
  config.amazon_secret_access_key = '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'
end
