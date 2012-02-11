ENV['RAILS_ASSET_ID'] = ''
NovelsOnLocation::Application.configure do
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.serve_static_assets = false
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  # custom
  config.main_host = 'novelsonlocation.com'
end