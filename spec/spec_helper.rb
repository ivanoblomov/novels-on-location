require 'simplecov'
SimpleCov.start

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
Object.send(:remove_const, :ActiveRecord) # hack to avoid mysterious ActiveRecord::ConnectionNotEstablished
require 'rspec/rails'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
