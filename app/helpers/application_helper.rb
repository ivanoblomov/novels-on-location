module ApplicationHelper
  include ScaffoldLogic::Helper

  def default_title
    "Novels: On Location - #{Location.book_count} Novels/#{Location.count} Locations"
  end

  def description_for_location locations, location_kind
    case location_kind
    when 'author'
      "#{locations.first.author} has #{locations.size == 1 ? 'a setting from the novel' : "#{locations.size} settings from the novels"} #{location @locations, :title} mapped on NovelsOnLocation.com, including #{location @locations, :address}."
    when 'novel'
      "#{locations.first.title}, a novel by #{locations.first.author}, has #{locations.size == 1 ? "the setting #{location @locations, :address}" : "#{locations.size} settings"} mapped on NovelsOnLocation.com#{", including #{location @locations, :address}" if @locations.size > 1}."
    when 'reader'
      "#{params[:reader]} mapped #{locations.size == 1 ? "the novel, #{locations.first.title}," : "#{locations.size} settings for the novels #{location @locations, :title}"} on NovelsOnLocation.com, including #{location @locations, :address}."
    end
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

  def location locations, attribute
    locations.map{ |l| %{"#{l.send attribute}"} }.uniq.sort.to_sentence
  end

  def safari_pc?
    !! (request.user_agent =~ /safari/i) && ! ios?
  end

  def title_for_location locations, location_kind
    case location_kind
    when 'author'
      "#{locations.first.author} - Novels: On Location"
    when 'novel'
      "#{location locations, :title} - Novels: On Location"
    when 'reader'
      "#{params[:reader]} - Novels: On Location"
    end
  end

  def wikipedia_link_to link_text, options={}
    return if link_text.blank?
    link_to link_text, "http://en.wikipedia.org/wiki/#{link_text.gsub ' ', '_'}", {:target => '_blank', :title => "Read about #{link_text} on Wikipedia"}.merge(options)
  end
end