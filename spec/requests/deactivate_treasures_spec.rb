RSpec.describe 'TreasuresController#deactivate', type: :request do
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
end
