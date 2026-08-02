# frozen_string_literal: true

Rails.root.glob('lib/ext/**/*.rb').each { |file| require file }
