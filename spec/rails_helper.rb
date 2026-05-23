# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

RSpec.configure do |config|
  # Remove this line to enable support for ActiveRecord
  config.use_active_record = false

  # If you enable ActiveRecord support you should uncomment these lines,
  # note if you'd prefer not to run each example within a transaction, you
  # should set use_transactional_fixtures to false.
  #
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/7-0/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
  config.before(:each, type: :request) do
    host! Rails.application.config.main_host
  end
  config.before(:each, type: :system) { driven_by :rack_test }
  config.before(:each, :js, type: :system) do |example|
    driven_by example.metadata[:js]
  end
  config.after do |example|
    if page.driver.respond_to?(:browser) && page.driver.browser
      logs = page.driver.browser.logs.get(:browser)

      if logs.present?
        warn "Config.after: begin logs for #{example.full_description}"
        logs.each do |log|
          warn "[#{Time.zone.at(log.timestamp / 1000).strftime('%H:%M:%S.%L')}] [#{log.level}] #{log.message}"
        end
        warn 'Config.after: end'
      end
    end
  rescue StandardError
    warn "Config.after: Can't capture browser logs! Session may be dead"
  end

  config.after(:each, type: :system) do |example|
    warn page.driver.browser.logs.get(:browser) if example.exception
  end
end
Capybara.configure do |config|
  config.default_driver = :selenium
  config.javascript_driver = :selenium
  config.app_host = "http://#{Rails.application.config.main_host}"
end
Capybara.always_include_port = true
Capybara.register_driver :selenium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options)
end
VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.configure_rspec_metadata!
  config.hook_into :webmock

  # Crucial: Don't leak your keys in the cassettes!
  config.filter_sensitive_data('<FACEBOOK_APP_ID>') { ENV.fetch('FACEBOOK_APP_ID', nil) }
  config.filter_sensitive_data('<GOOGLE_MAPS_API_KEY>') { ENV.fetch('GOOGLE_MAPS_API_KEY', nil) }
  config.filter_sensitive_data('<SENDGRID_PASSWORD>') { ENV.fetch('SENDGRID_PASSWORD', nil) }
  config.filter_sensitive_data('<SENDGRID_USERNAME>') { ENV.fetch('SENDGRID_USERNAME', nil) }
  config.filter_sensitive_data('<TWITTER_ACCESS_SECRET>') { ENV.fetch('TWITTER_ACCESS_SECRET', nil) }
  config.filter_sensitive_data('<TWITTER_ACCESS_TOKEN>') { ENV.fetch('TWITTER_ACCESS_TOKEN', nil) }
  config.filter_sensitive_data('<TWITTER_CONSUMER_KEY>') { ENV.fetch('TWITTER_CONSUMER_KEY', nil) }
  config.filter_sensitive_data('<TWITTER_CONSUMER_SECRET>') { ENV.fetch('TWITTER_CONSUMER_SECRET', nil) }
end
