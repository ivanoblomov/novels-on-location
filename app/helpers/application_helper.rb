module ApplicationHelper
  def filter_param(value)
    "'#{value.blank? ? nil : j(value)}'"
  end

  def ie?
    !! (request.user_agent =~ /msie/i)
  end

  def ios?
    !! (request.user_agent =~ /ipad|iphone/i)
  end

  def safari_pc?
    !! (request.user_agent =~ /safari/i) && ! ios?
  end
end