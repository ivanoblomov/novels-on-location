module Heroku
  class StaticAssetsMiddleware
    def cache_static_asset(reply)
      return reply unless can_cache?(reply)
      status, headers, response = reply
      headers['Cache-Control'] = 'public, max-age=31556926' # 1 year
      headers['Vary'] = 'Accept-Encoding'
      build_new_reply(status, headers, response)
    end
  end
end