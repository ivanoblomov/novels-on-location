# frozen_string_literal: true

# Define attributes common to all Mailers.
class ApplicationMailer < ActionMailer::Base
  default from: 'ed@novelsonlocation.com'
  layout 'mailer'
end
