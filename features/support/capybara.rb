# frozen_string_literal: true

require 'capybara/cucumber'
require 'selenium-webdriver'

Capybara.configure do |config|
  config.default_max_wait_time = 5 # seconds
  config.default_driver = :selenium
  config.javascript_driver = :selenium
  config.app_host = 'http://localhost:3000'
end
Capybara.always_include_port = true
Capybara.server = :puma
Capybara.register_driver :selenium do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options)
end
