ENV['RAILS_ASSET_ID'] = ''
NovelsOnLocation::Application.configure do
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'
  config.active_support.deprecation = :notify
  config.assets.compile = false
  config.assets.compress = true
  config.assets.digest = true
  config.assets.precompile += %w(ie.css ios.css print.css safari.css)
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.i18n.fallbacks = true
  config.serve_static_assets = true
  config.static_cache_control = 'public, max-age=31556926'
  # custom
  config.main_host = 'novelsonlocation.com'
end