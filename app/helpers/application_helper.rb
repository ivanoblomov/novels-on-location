module ApplicationHelper
  include ScaffoldLogic::Helper

  def default_title
    "Novels: On Location - #{Location.book_count} Novels/#{Location.count} Locations"
  end

  def filter_param(value)
    "'#{value.blank? ? nil : j(value)}'"
  end

  def google_link_to link_text, options={}
    link_to link_text, "http://www.google.com/search?q=#{u link_text}", {:target => '_blank', :title => "Google #{link_text}"}.merge(options)
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
    link_to link_text, "http://en.wikipedia.org/wiki/#{link_text.gsub ' ', '_'}", {:target => '_blank', :title => "Read about #{link_text} on Wikipedia"}.merge(options)
  end
end