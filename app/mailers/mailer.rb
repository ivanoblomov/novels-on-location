# frozen_string_literal: true

# Outgoing mail
class Mailer < ApplicationMailer
  layout false

  def error(request, exception)
    @exception = exception
    @request = request
    mail to: Rails.application.config.admin_email,
         from: Rails.application.config.admin_email,
         subject: @exception.class
  end
end
