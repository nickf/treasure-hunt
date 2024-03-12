class GuessesController < ApplicationController
  def create
    begin
      find_treasure
      record_guess
      validate_guess
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e }, status: :not_found
      return
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: @guess.errors.full_messages }, status: :bad_request
      return
    end

    render json: { message: 'Thank you! You will receive an email if your guess wins!' }, status: :created
  end

  private

  def find_treasure
    @treasure = Treasure.active.find_by_id(params[:treasure_id])

    if @treasure.blank?
      raise ActiveRecord::RecordNotFound, "Could not find active treasure hunt for ID #{params[:treasure_id]}"
    end
  end

  def record_guess
    @guess = Guess.new(**guess_params, treasure: @treasure)
    @guess.save!
  end

  def validate_guess
    result = @treasure.validate_guess(@guess)

    if result[:winner]
      @guess.mark_as_winner!(@treasure, result[:distance])
    end
  end

  def guess_params
    params.permit(:email, :answer)
  end
end
