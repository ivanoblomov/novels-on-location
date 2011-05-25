module ApplicationHelper
  def to_google_lat_lng( lat_lng_array )
    "new google.maps.LatLng(#{@location.lat_lng * ', '})"
  end
end
