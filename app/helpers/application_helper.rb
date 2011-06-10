module ApplicationHelper
  def filter_param(value)
    "'#{value.blank? ? nil : escape_javascript(value)}'"
  end

  def to_google_lat_lng( lat_lng_array )
    "new google.maps.LatLng(#{lat_lng_array * ', '})"
  end
end
