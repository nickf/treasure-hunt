require_relative 'concerns/geolocation_validations'

class Treasure < ApplicationRecord
  WINNER_DEFAULT_PAGE_SIZE = 20
  WINNING_THRESHOLD = 1

  include GeolocationValidations

  geocoded_by :answer

  validates :answer, presence: true, uniqueness: { scope: :active, message: 'already exists for another active treasure hunt' }
  validate :answer_is_valid_address

  after_validation :geocode, :coordinates_are_geocoded

  has_many :guesses, dependent: :delete_all

  scope :active, -> { where(active: true) }

  def deactivate!
    self.update!(active: false)
  end

  def classify_guess(guess)
    # Determine the km distance between 
    # the treasure location, and the guess 
    distance = Geocoder::Calculations.distance_between(
      [self.latitude, self.longitude],
      [guess.latitude, guess.longitude],
      units: :km
    )

    # Threshold is 1000m = 1km
    is_winner = distance < WINNING_THRESHOLD

    return { winner: is_winner, distance: distance }
  end

  def winners(params)
    page = params[:page] || 1
    per_page = params[:per_page] || WINNER_DEFAULT_PAGE_SIZE
    order = params[:order] || 'asc'

    return self.guesses
      .winner
      .order(winning_distance: order)
      .paginate(page: page, per_page: per_page)
  end
end
