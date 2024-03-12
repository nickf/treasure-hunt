FactoryBot.define do
  factory :treasure do
    answer { 'Add a valid answer here' }
    active { true }
  end

  factory :guess do
    treasure { association :treasure }
    answer { 'Add a valid answer here ' }
    email { 'test-user@example.com' }
    is_winner { false }
  end
end