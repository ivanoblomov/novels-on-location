# frozen_string_literal: true

ActionMailer::Base.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: '587',
  authentication: :plain,
  user_name: ENV.fetch('SENDGRID_USERNAME'),
  password: ENV.fetch('SENDGRID_PASSWORD'),
  domain: 'heroku.com'
}
ActionMailer::Base.delivery_method = :smtp
