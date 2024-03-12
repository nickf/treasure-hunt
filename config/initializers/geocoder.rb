Geocoder.configure(
  # Geocoding options
  timeout: 10,                 # geocoding service timeout (secs)
  lookup: :nominatim,          # name of geocoding service (symbol)
  ip_lookup: :ipinfo_io,       # name of IP address geocoding service (symbol)
  language: :en,               # ISO-639 language code
)
