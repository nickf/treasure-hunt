RSpec.describe 'TreasuresController#destroy', type: :request do
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