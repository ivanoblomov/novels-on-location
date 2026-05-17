# frozen_string_literal: true

# Outgoing mail
class Mailer < ApplicationMailer
  def error(request, exception)
    @exception = exception
    @request = request
    mail to: Rails.application.config.admin_email,
         from: Rails.application.config.admin_email,
         subject: "#{Rails.application.config.main_host} Error: #{@exception
                                                                  .message}"
  end
end
