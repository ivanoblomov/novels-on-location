module ApplicationHelper
  def filter_param(value)
    "'#{value.blank? ? nil : j(value)}'"
  end
end
