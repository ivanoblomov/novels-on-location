# frozen_string_literal: true

# Define attributes common to all Mailers.
class ApplicationMailer < ActionMailer::Base
  default from: "ed@#{Rails.application.config.main_host}"
  layout 'mailer'
end
