module ApplicationHelper
  include ScaffoldLogic::Helper

  def filter_param(value)
    "'#{value.blank? ? nil : j(value)}'"
  end

  def google_link_to link_text, options={}
    link_to link_text, "http://www.google.com/search?q=#{u link_text}", options
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

  def wikipedia_link_to link_text, options={}
    link_to link_text, "http://en.wikipedia.org/wiki/#{u link_text}", options
  end
end