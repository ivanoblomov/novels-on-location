# frozen_string_literal: true

# General view helpers
module ApplicationHelper
  include ScaffoldLogic::Helper

  def author_link_to(location)
    return if location.author.blank?

    link_to "All Novels by #{location.author}",
            author_url(location),
            title: "Show all novels by #{location.author}"
  end

  def author_url(location)
    "#!author-#{u location.author}"
  end

  def default_title
    "Novels: On Location - #{Location.book_count} Novels/#{Location.count} " \
      'Locations'
  end

  def facebook_link_to(location)
    # rubocop:disable Rails/HelperInstanceVariable
    link_to @user_name || 'Reader',
            "https://www.facebook.com/pages/PageName/#{location.user_id}",
            target: '_blank',
            title: "Go to #{@user_name || 'Reader'}'s page on Facebook", rel: 'noopener'
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def filter_param!(value)
    # rubocop:disable Rails/OutputSafety
    "'#{j(value) if value.present?}'".html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def google_link_to(link_text, options = {})
    link_to link_text,
            "https://www.google.com/search?q=#{u link_text}",
            { target: '_blank', title: "Google #{link_text}" }.merge(options)
  end

  def ie?
    request.user_agent =~ /msie/i
  end

  def ios?
    request.user_agent =~ /ipad|iphone/i
  end

  def location(locations, attribute)
    locations.map { |l| %("#{l.send attribute}") }.uniq.sort.to_sentence
  end

  def novel_link_to(location)
    link_to "All Locations for #{location.title}",
            novel_url(location),
            title: "Show all locations for #{location.title}"
  end

  def novel_url(location)
    "#!novel-#{u location.title_for_regex}"
  end

  def phrase_for_novel(locations)
    %("#{locations.first.title}", a novel by #{locations.first.author},)
  end

  def place_url(location)
    "#!place-#{u location.place}"
  end

  def reader_link_to(location)
    return if location.user_id.blank?

    # rubocop:disable Rails/HelperInstanceVariable
    link_to "All Pins by #{@user_name || 'Reader'}",
            reader_url(location),
            title: "Show all pins added by #{@user_name || 'Reader'}"
    # rubocop:enable Rails/HelperInstanceVariable
  end

  def reader_url(location)
    "#!reader-#{location.user_id}"
  end

  def safari_pc?
    request.user_agent =~ /safari/i && !ios?
  end

  def wikipedia_link_to(link_text, options = {})
    return if link_text.blank?

    link_to link_text,
            "https://en.wikipedia.org/wiki/#{u link_text.tr(' ', '_')}",
            {
              target: '_blank', title: "Read about #{link_text} on Wikipedia"
            }.merge(options)
  end
end
