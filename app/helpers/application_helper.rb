# frozen_string_literal: true

# General view helpers
# rubocop:disable Metrics/ModuleLength
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
    sort_args = sort_args(field, params)
    sort_url_params = sort_url_params(field, sort_args[:dir], html_options)
    html_options[:class] = [sort_args[:classname], html_options[:class]].compact * ' ' if sort_args[:classname]

    sort_field = sort_field(field)
    html_options[:title] ||= "Sort by #{sort_field}"

    link_to(sort_field, sort_url(model, sort_url_params), html_options)
  end

  def wikipedia_link_to(link_text, options = {})
    return if link_text.blank?

    link_to link_text,
            "https://en.wikipedia.org/wiki/#{u link_text.tr(' ', '_')}",
            {
              target: '_blank', title: "Read about #{link_text} on Wikipedia"
            }.merge(options)
  end

  private

  def sort_args(field, params)
    sort_args = { dir: 'asc' }
    if (field.to_sym == params[:by] || field == params[:by]) && params[:dir] == 'asc'
      sort_args[:classname] = 'arrow-asc'
      sort_args[:dir] = 'desc'
    elsif field.to_sym == params[:by] || field == params[:by]
      sort_args[:classname] = 'arrow-desc'
      sort_args[:dir] = 'asc'
    end
    sort_args
  end

  def sort_field(field)
    params[:labels] && params[:labels][field] ? params[:labels][field] : field.titleize
  end

  def sort_url(model, url_params)
    model.is_a?(Symbol) ? public_send("#{model}_url", url_params) : "/#{model}?#{url_params.compact.to_query}"
  end

  def sort_url_params(field, dir, html_options)
    url_params = {
      anchor: html_options[:anchor],
      by: field,
      dir: dir,
      search: params[:search],
      category: params[:category],
      show: params[:show]
    }
    url_params[:show] = params[:show] unless params[:show].blank? || params[:show] == 'all'
    url_params
  end
end
# rubocop:enable Metrics/ModuleLength
