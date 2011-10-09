class Mailer < ActionMailer::Base
  def error request, exception
    @exception = exception
    @request = request
    mail :to => Rails.application.config.admin_email, :from => Rails.application.config.admin_email, :subject => "NovelsOnLocation.com Error: #{@exception.message}"
  end
end