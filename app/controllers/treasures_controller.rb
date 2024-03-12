class TreasuresController < ApplicationController
  MAX_PAGE_SIZE = 100
  PAGE_ORDER_OPTIONS = %w( asc desc )

  before_action :get_treasure, except: [:create]

  def create
    begin
      treasure = Treasure.new(**treasure_params, active: true)
      treasure.save!
    rescue ActiveRecord::RecordInvalid => err
      render json: { error: treasure.errors.full_messages }, status: :bad_request
      return
    end

    render json: treasure, status: :created
  end

  def winners
    begin
      validate_page_options!
    rescue TypeError => e
      render json: { error: e.message }, status: :bad_request
      return
    end

    winners = @treasure.winners(params)

    render json: { data: winners }, status: :ok
  end

  def deactivate
    @treasure.deactivate!
    @treasure.reload

    render json: @treasure, status: :ok
  end

  def destroy
    @treasure.destroy!

    head :no_content
  end

  private

  def treasure_params
    params.permit(:answer)
  end

  def get_treasure
    begin
      @treasure = Treasure.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e }, status: :not_found
      return
    end
  end

  def validate_page_options!
    validate_page_size!(params[:per_page])
    validate_page_ordering!(params[:order])
  end

  def validate_page_size!(per_page = nil)
    if per_page
      page_size = per_page.to_i

      if page_size < 1 || page_size > MAX_PAGE_SIZE
        raise TypeError, "per_page must be a value between 1 and #{MAX_PAGE_SIZE}"
      end
    end
  end

  def validate_page_ordering!(order = nil)
    if order && !PAGE_ORDER_OPTIONS.include?(order)
      raise TypeError, "order must be one of the following values: #{PAGE_ORDER_OPTIONS.join(', ')}"
    end
  end
end
