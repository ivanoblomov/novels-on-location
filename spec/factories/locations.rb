# frozen_string_literal: true

FactoryBot.define do
  factory :location do
    id { 1 }
  end

  trait :from_ios do
    user_token { 'B6AA2BE7-3374-4348-800F-A3844694E1FA' }
  end

  trait :not_from_ios do
    user_token { 'x44R8BY+xXfcUNviI36ohpqrdztm+ibnLQUddKBy0IE=' }
  end
end
