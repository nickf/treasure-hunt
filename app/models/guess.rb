require_relative 'concerns/geolocation_validations'

class Guess < ApplicationRecord
  EMAIL_REGEX = Regexp.new('^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$')

  include GeolocationValidations

  geocoded_by :answer

  validates :email, presence: true, format: { with: EMAIL_REGEX, message: 'must be a valid email address', multiline: true }
  validates :answer, presence: true
  validate :answer_is_valid_address
  validate :not_already_winner_for_treasure

  after_validation :geocode, :coordinates_are_geocoded

  belongs_to :treasure

  scope :winner, -> { where(is_winner: true) }

  def mark_as_winner!(treasure, distance)
    # Geocoder distances are measured in km while we format to m
    winning_distance = distance * 100

    Rails.logger.info("[!!!  WINNER !!!] Winning guess for treasure_id #{self.treasure_id} - Email: #{self.email}, Answer: #{self.answer}, Distance: #{winning_distance}m")
    self.update!(is_winner: true, winning_distance: winning_distance)
    GuessMailer.with(guess: self, treasure: treasure).winner.deliver_later
  end

  private

  def not_already_winner_for_treasure
    if Guess.exists?(treasure_id: treasure_id, email: email, is_winner: true)
      errors.add(:email, 'user has already won on this treasure hunt')
    end
  end
end
