require 'swagger_helper'

RSpec.describe 'TreasuresController#winners', type: :request do
  describe 'GET /treasures/{id}/winners' do
    before :all do
      @treasure_with_winners = create(:treasure, answer: '867 Magnolia St., Los Angeles, CA 90051', active: true)

      25.times do |i|
        create(:guess, treasure: @treasure_with_winners, email: "test-user-#{i}@example.com", answer: "865 Magnolia St., Los Angeles, CA 90051", is_winner: true, winning_distance: i)
      end
    end

    after :all do
      @treasure_with_winners.destroy!
    end

    path '/treasures/{id}/winners' do
      get 'Fetch the current winning guesses for the treasure hunt' do
        tags 'Treasure Hunts'
        consumes 'application/json'

        parameter name: :id, in: :path, type: :string
        parameter name: :page, in: :query, type: :string, required: false
        parameter name: :per_page, in: :query, type: :string, required: false
        parameter name: :order, in: :query, type: :string, required: false
        
        response '200', 'returns a list of winners' do
          schema type: :object,
          properties: {
            data: { type: 'array' },
          }

          let(:id) { @treasure_with_winners.id }
          run_test!
        end

        response '400', 'invalid request' do
          schema type: :object,
          properties: {
            error: { type: :string }
          }

          let(:id) { @treasure_with_winners.id }
          let(:per_page) { -1 }
          run_test!
        end

        response '404', 'treasure hunt not found' do
          schema type: :object,
          properties: {
            error: { type: :string }
          }

          let(:id) { 'non-id' }
          run_test!
        end
      end
    end

    describe 'when there are winning guesses on the treasure hunt' do
      it 'lists the winning guesses in order of increasing distance' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'asc' }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(Treasure::WINNER_DEFAULT_PAGE_SIZE)
        expect(response_body['data'][0]['winning_distance']).to eql(0)
        expect(response_body['data'][-1]['winning_distance']).to eql(19)
      end

      it 'lists the winning guesses in order of decreasing distance' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'desc' }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(Treasure::WINNER_DEFAULT_PAGE_SIZE)
        expect(response_body['data'][0]['winning_distance']).to eql(24)
        expect(response_body['data'][-1]['winning_distance']).to eql(5)
      end

      it 'lists the winning guesses in order of increasing distance if no order is passed' do
        get "/treasures/#{@treasure_with_winners.id}/winners"

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(Treasure::WINNER_DEFAULT_PAGE_SIZE)
        expect(response_body['data'][0]['winning_distance']).to eql(0)
        expect(response_body['data'][-1]['winning_distance']).to eql(19)
      end

      it 'respects page sizing' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { per_page: 10 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(10)
        expect(response_body['data'][0]['winning_distance']).to eql(0)
        expect(response_body['data'][-1]['winning_distance']).to eql(9)
      end

      it 'respects page sizing and increasing distance order' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'asc', page: 2, per_page: 10 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(10)
        expect(response_body['data'][0]['winning_distance']).to eql(10)
        expect(response_body['data'][-1]['winning_distance']).to eql(19)

        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'asc', page: 3, per_page: 10 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(5)
        expect(response_body['data'][0]['winning_distance']).to eql(20)
        expect(response_body['data'][-1]['winning_distance']).to eql(24)
      end

      it 'respects page sizing and decreasing distance order' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'desc', page: 2, per_page: 10 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(10)
        expect(response_body['data'][0]['winning_distance']).to eql(14)
        expect(response_body['data'][-1]['winning_distance']).to eql(5)

        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'desc', page: 3, per_page: 10 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data'].size).to eql(5)
        expect(response_body['data'][0]['winning_distance']).to eql(4)
        expect(response_body['data'][-1]['winning_distance']).to eql(0)
      end
    end

    describe 'when there are no winning guesses on the treasure hunt' do
      before :all do
        @treasure_without_winners = create(:treasure, answer: '869 Magnolia St., Los Angeles, CA 90051', active: true)
      end

      after :all do
        @treasure_without_winners.destroy!
      end

      it 'returns an empty list' do
        get "/treasures/#{@treasure_without_winners.id}/winners"

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data']).to eql([])
      end

      it 'returns an empty list even with page options' do
        get "/treasures/#{@treasure_without_winners.id}/winners", params: { order: 'desc', page: 1, per_page: 10 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)

        expect(response_body['data']).to eql([])
      end 
    end

    describe 'when parameters are invalid' do
      it 'returns a 404 if the treasure hunt cannot be found' do
        get "/treasures/no-id/winners"

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(response_body['error']).to eql("Couldn't find Treasure with 'id'=no-id")
      end

      it 'returns a 400 if the order param is not supported' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { order: 'invalid' }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(response_body['error']).to eql("order must be one of the following values: #{TreasuresController::PAGE_ORDER_OPTIONS.join(', ')}")
      end

      it 'returns a 400 if the page size is less than 1' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { per_page: -1 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(response_body['error']).to eql("per_page must be a value between 1 and #{TreasuresController::MAX_PAGE_SIZE}")
      end

      it 'returns a 400 if the page size is greater than the max page size' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { per_page: TreasuresController::MAX_PAGE_SIZE + 1 }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(response_body['error']).to eql("per_page must be a value between 1 and #{TreasuresController::MAX_PAGE_SIZE}")
      end

      it 'returns a 400 if the page size is not numeric' do
        get "/treasures/#{@treasure_with_winners.id}/winners", params: { per_page: 'not-a-number' }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(response_body['error']).to eql("per_page must be a value between 1 and #{TreasuresController::MAX_PAGE_SIZE}")
      end
    end
  end
end
