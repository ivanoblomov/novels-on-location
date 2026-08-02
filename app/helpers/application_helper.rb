# frozen_string_literal: true

# General view helpers
module ApplicationHelper
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

  def novel_link_to(location)
    link_to "All Locations for #{location.title}",
            novel_url(location),
            title: "Show all locations for #{location.title}"
  end

  def novel_url(location)
    "#!novel-#{u location.title_for_regex}"
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

  # Returns a link_to tag with sorting parameters that can be used with ActiveRecord.order_by.
  #
  # To use standard resources, specify the resources as a plural symbol:
  #   sort_link(:users, 'email', params)
  #
  # To use resources aliased with :as (in routes.rb), specify the aliased route as a string.
  #   sort_link('users_admin', 'email', params)
  #
  # You can override the link's label by adding a labels hash to your params in the controller:
  #   params[:labels] = {'user_id' => 'User'}
  def sort_link(model, field, params, html_options = {})
    if (field.to_sym == params[:by] || field == params[:by]) && params[:dir] == 'asc'
      classname = 'arrow-asc'
      dir = 'desc'
    elsif field.to_sym == params[:by] || field == params[:by]
      classname = 'arrow-desc'
      dir = 'asc'
    else
      dir = 'asc'
    end

    options = {
      anchor: html_options[:anchor],
      by: field,
      dir: dir,
      search: params[:search],
      category: params[:category],
      show: params[:show]
    }

    options[:show] = params[:show] unless params[:show].blank? || params[:show] == 'all'
    html_options[:class] = [classname, html_options[:class]].compact * ' ' if classname

    field_name = params[:labels] && params[:labels][field] ? params[:labels][field] : field.titleize
    html_options[:title] ||= "Sort by #{field_name}"

    _link = model.is_a?(Symbol) ? eval("#{model}_url(options)") : "/#{model}?#{options.to_params}"
    link_to(field_name, _link, html_options)
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
