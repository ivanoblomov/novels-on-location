# frozen_string_literal: true

ENV['RAILS_ASSET_ID'] = ''
NovelsOnLocation::Application.configure do
  config.assume_ssl = true
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'
  config.active_support.deprecation = :notify
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.log_level = :info
  # custom
  config.main_host = 'novelsonlocation.com'
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=31536000, immutable'
  }
end
