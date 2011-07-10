module ApplicationHelper
  def filter_param(value)
    "'#{value.blank? ? nil : escape_javascript(value)}'"
  end
end
