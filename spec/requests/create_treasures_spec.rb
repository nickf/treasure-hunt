require 'swagger_helper'

RSpec.describe 'TreasuresController#create', type: :request do
  describe 'POST /treasures' do

    path '/treasures' do
      post 'Creates a new treasure hunt' do
        tags 'Treasure Hunts'
        consumes 'application/json'
        parameter name: :treasure, in: :body, type: :string, schema: {
          type: :object,
          properties: {
            answer: { type: :string, required: true }
          },
          required: ['answer']
        }
        
        response '201', 'treasure hunt created' do
          schema type: :object,
          properties: {
            id: { type: :integer },
            answer: { type: :string },
            active: { type: :boolean },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

          let(:treasure) { { answer: '859 Magnolia St., Los Angeles, CA 90051' }}
          run_test!
        end

        response '400', 'treasure hunt invalid' do
          schema type: :object,
          properties: {
            error: { type: 'array', items: { type: :string } }
          }

          let(:treasure) {}

          run_test!
        end
      end
    end  

    describe 'for valid data' do
      it 'returns a 201 with the newly created treasure object' do
        post '/treasures', params: { answer: '865 Magnolia St., Los Angeles, CA 90051' }
  
        expect(response).to have_http_status(:created)
  
        response_body = JSON.parse(response.body)
  
        expect(response_body['answer']).to eq("865 Magnolia St., Los Angeles, CA 90051")
        expect(response_body['latitude']).to be_present
        expect(response_body['longitude']).to be_present
        expect(response_body['active']).to eq(true)
        expect(response_body['created_at']).to be_present
        expect(response_body['updated_at']).to be_present

        Treasure.find_by_id(response_body['id']).destroy!
      end

      it 'returns a 201 with the newly created treasure object even if it exists on a deactivated hunt' do
        treasure = create(:treasure, answer: '865 Magnolia St., Los Angeles, CA 90051', active: false)

        post '/treasures', params: { answer: '865 Magnolia St., Los Angeles, CA 90051' }
  
        expect(response).to have_http_status(:created)
  
        response_body = JSON.parse(response.body)
  
        expect(response_body['answer']).to eq("865 Magnolia St., Los Angeles, CA 90051")
        expect(response_body['latitude']).to be_present
        expect(response_body['longitude']).to be_present
        expect(response_body['active']).to eq(true)
        expect(response_body['created_at']).to be_present
        expect(response_body['updated_at']).to be_present

        treasure.destroy!
      end
    end  

    describe 'for invalid data' do
      describe 'when the answer is not passed' do
        it 'returns a 400 with invalid parameters' do
          post '/treasures', params: {}
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer can't be blank"])
        end
      end

      describe 'when the answer is not a string' do
        it 'returns a 400 if the answer is an integer' do
          post '/treasures', params: { answer: 0 }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer must be a valid street address"])
        end
      end

      describe 'when the answer is not a string' do
        it 'returns a 400 if the answer is a boolean' do
          post '/treasures', params: { answer: true }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer must be a valid street address"])
        end
      end

      describe 'when the answer is not a valid location' do
        it 'returns a 400 if the answer is not a valid location' do
          post '/treasures', params: { answer: '1234 Anywhere St., Nowhere, CA' }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer geolocation failed - please enter a valid location"])
        end
      end

      describe 'when the answer already exists on another active treasure hunt' do
        it 'returns a 400' do
          treasure = create(:treasure, answer: '865 Magnolia St., Los Angeles, CA 90051', active: true)

          post '/treasures', params: { answer: '865 Magnolia St., Los Angeles, CA 90051' }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer already exists for another active treasure hunt"])

          treasure.destroy!
        end
      end
    end  
  end

  describe 'PUT treasures/{id}/deactivate' do
    path '/treasures/{id}/deactivate' do
      put 'Deactivates a treasure hunt, stopping any further guesses from being made' do
        tags 'Treasure Hunts'
        consumes 'application/json'
        parameter name: :id, in: :path, type: :string
        
        response '200', 'returns the deactivated treasure hunt' do
          schema type: :object,
          properties: {
            id: { type: :integer },
            answer: { type: :string },
            active: { type: :boolean },
            created_at: { type: :string },
            updated_at: { type: :string }
          }

          let (:id) { create(:treasure, answer: '871 Magnolia St., Los Angeles, CA 90051').id }
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

    describe 'when the treasure hunt exists' do
      it 'returns deactivates the record and returns a 200' do
        treasure = create(:treasure, answer: '865 Magnolia St., Los Angeles, CA 90051', active: true)

        put "/treasures/#{treasure.id}/deactivate"
    
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(response_body['id']).to eql(treasure.id)
        expect(response_body['active']).to eql(false)
      end
    end

    describe 'when the treasure hunt does not exist' do
      it 'returns a 404' do
        put "/treasures/no-id/deactivate"
    
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(response_body['error']).to eql("Couldn't find Treasure with 'id'=no-id")
      end
    end
  end

  describe 'DELETE treasures/{id}' do
    path '/treasures/{id}' do
      delete 'Deletes a treasure hunt' do
        tags 'Treasure Hunts'
        consumes 'application/json'
        parameter name: :id, in: :path, type: :string
        
        response '204', 'no content response, confirms delete' do
          let(:id) { create(:treasure, answer: '871 Magnolia St., Los Angeles, CA 90051').id }
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

    describe 'when the treasure hunt exists' do
      it 'returns deletes the record and returns a 204' do
        treasure = create(:treasure, answer: '865 Magnolia St., Los Angeles, CA 90051', active: false)

        delete "/treasures/#{treasure.id}"
    
        expect(response).to have_http_status(:no_content)

        expect(Treasure.exists?(id: treasure.id)).to eql(false)
      end
    end

    describe 'when the treasure hunt does not exist' do
      it 'returns a 404' do
        delete "/treasures/no-id"
    
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(response_body['error']).to eql("Couldn't find Treasure with 'id'=no-id")
      end
    end
  end
end
