# frozen_string_literal: true

use Rack::Deflater
require ::File.expand_path('config/environment', __dir__)
run NovelsOnLocation::Application
