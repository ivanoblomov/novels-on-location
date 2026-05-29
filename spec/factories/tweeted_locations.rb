# frozen_string_literal: true

FactoryBot.define do
  factory :tweeted_location do
    location
    text { Faker::Lorem.sentence }
  end
end
