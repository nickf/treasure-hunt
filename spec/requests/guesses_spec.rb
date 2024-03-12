require 'factory_bot'
require 'swagger_helper'

RSpec.describe 'GuessesController', type: :request do
  describe 'POST /guesses' do
    before :all do
      @valid_email = 'test-user@example.com'
      @valid_answer = '7079 Beach St., Los Angeles, CA 90045'
      @treasure = create(:treasure, answer: @valid_answer, active: true)
    end

    after :all do
      @treasure.destroy!
    end

    path '/guesses' do
      post 'Creates a new guess' do
        tags 'Guesses'
        consumes 'application/json'
        parameter name: :guess, in: :body, type: :string, schema: {
          type: :object,
          properties: {
            answer: { type: :string, required: true },
            email: { type: :string, required: true },
            treasure_id: { type: :integer, required: true }
          },
          required: ['answer', 'email', 'treasure_id']
        }
        
        response '201', 'guess recorded' do
          schema type: :object,
          properties: {
            message: { type: :string }
          }

          let(:guess) { { treasure_id: @treasure.id, answer: @valid_answer, email: @valid_email }}
          run_test!
        end

        response '400', 'guess invalid' do
          schema type: :object,
          properties: {
            error: { type: 'array', items: { type: :string } }
          }

          let(:guess) { { treasure_id: @treasure.id } }

          run_test!
        end

        response '404', 'treasure hunt not found' do
          schema type: :object,
          properties: {
            error: { type: :string }
          }

          let(:guess) { { treasure_id: 'non-id', answer: @valid_answer, email: @valid_email }}
          run_test!
        end
      end
    end

    describe 'for a valid winning guess' do
      it 'returns a 201' do
        mailer_double = instance_double(GuessMailer)
        message_delivery_double = instance_double(ActionMailer::MessageDelivery)

        expect(GuessMailer).to receive(:with).with(guess: kind_of(Guess), treasure: @treasure).and_return(mailer_double)
        expect(mailer_double).to receive(:winner).and_return(message_delivery_double)
        expect(message_delivery_double).to receive(:deliver_later).once    

        post '/guesses', params: { email: @valid_email, treasure_id: @treasure.id, answer: @valid_answer }
  
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:created)
        expect(response_body['message']).to eql("Thank you! You will receive an email if your guess wins!")
      end
    end  

    describe 'for a valid losing guess' do
      it 'returns a 201' do
        expect(GuessMailer).not_to receive(:with)

        post '/guesses', params: { email: 'diff-user@example.com', treasure_id: @treasure.id, answer: '7640 3rd St., Los Angeles, CA 90140' }
  
        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:created)
        expect(response_body['message']).to eql("Thank you! You will receive an email if your guess wins!")
      end
    end

    describe 'for a valid guess but the treasure hunt is inactive' do
      it 'returns a 404' do
        inactive_treasure = create(:treasure, answer: "7640 3rd St., Los Angeles, CA 90140", active: false)

        post '/guesses', params: { email: @valid_email, treasure_id: inactive_treasure.id, answer: @valid_answer }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:not_found)
        expect(response_body['error']).to eql("Could not find active treasure hunt for ID #{inactive_treasure.id}")

        inactive_treasure.destroy!
      end
    end

    describe 'for a valid guess but the user already has a winning guess for the treasure' do
      it 'returns a 400' do
        winning_user = 'winning-user@example.com'
        winning_guess = create(:guess, treasure: @treasure, is_winner: true, answer: "7640 3rd St., Los Angeles, CA 90140", email: winning_user)

        post '/guesses', params: { email: winning_user, treasure_id: @treasure.id, answer: @valid_answer }

        response_body = JSON.parse(response.body)

        expect(response).to have_http_status(:bad_request)
        expect(response_body['error']).to eql(["Email user has already won on this treasure hunt"])

        winning_guess.destroy!
      end
    end

    describe 'for invalid data' do
      describe 'when the answer is not passed' do
        it 'returns a 400 with invalid parameters' do
          post '/guesses', params: { email: 'answer-missing@example.com', treasure_id: @treasure.id }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer can't be blank"])
        end
      end
  
      describe 'when the answer is not a string' do
        it 'returns a 400 if the answer is an integer' do
          post '/guesses', params: { email: 'answer-invalid@example.com', treasure_id: @treasure.id, answer: 0 }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer must be a valid street address"])
        end
      end
  
      describe 'when the answer is not a string' do
        it 'returns a 400 if the answer is a boolean' do
          post '/guesses', params: { email: 'answer-invalid@example.com', treasure_id: @treasure.id, answer: true }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer must be a valid street address"])
        end
      end
  
      describe 'when the answer is not a valid location' do
        it 'returns a 400 if the answer is not a valid location' do
          post '/guesses', params: { email: 'answer-invalid@example.com', treasure_id: @treasure.id, answer: '1234 Anywhere St., Nowhere, CA' }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Answer geolocation failed - please enter a valid location"])
        end
      end

      describe 'when the email is not passed' do
        it 'returns a 400 with invalid parameters' do
          post '/guesses', params: { answer: @valid_answer, treasure_id: @treasure.id }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Email can't be blank"])
        end
      end

      describe 'when the email is not a valid email address' do
        it 'returns a 400 with invalid parameters' do
          post '/guesses', params: { answer: @valid_answer, treasure_id: @treasure.id, email: 'not an email' }
  
          response_body = JSON.parse(response.body)

          expect(response).to have_http_status(:bad_request)
          expect(response_body['error']).to eq(["Email must be a valid email address"])
        end
      end
    end    
  end
end
