require 'geocoder'

module GeolocationValidations
  extend ActiveSupport::Concern

  ADDRESS_REGEX = /^[#.0-9]+\s+[#.0-9a-zA-Z\s,-]+$/
  
  def answer_is_valid_address
    if (self.answer.present? && !self.answer.match(ADDRESS_REGEX))
      self.errors.add(:answer, "must be a valid street address")
      raise ActiveRecord::RecordInvalid
    end
  end

  def coordinates_are_geocoded
    if self.answer.present? && (self.latitude.blank? || self.longitude.blank?)
      self.errors.add(:answer, "geolocation failed - please enter a valid location")
      raise ActiveRecord::RecordInvalid
    end
  end
end