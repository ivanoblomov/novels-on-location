custom_date_formats = {
  date_time: '%b %e, %Y %I:%M %p',
  w3c_datetime: '%Y-%m-%d'
}
Date::DATE_FORMATS.merge! custom_date_formats
Time::DATE_FORMATS.merge! custom_date_formats
