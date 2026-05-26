# frozen_string_literal: true

NovelsOnLocation::Application.configure do
  config.cache_classes = true
  config.whiny_nils = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :letter_opener
  config.active_support.deprecation = :stderr
  config.eager_load = false
  # custom
  config.main_host = 'localhost'
end
