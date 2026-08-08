# frozen_string_literal: true

NovelsOnLocation::Application.configure do
  config.assume_ssl = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener
  config.active_support.deprecation = :log
  config.eager_load = false
  config.time_zone = 'America/New_York'
  # custom
  config.main_host = 'novels.test'
end
