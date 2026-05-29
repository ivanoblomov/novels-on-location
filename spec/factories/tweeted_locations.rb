# frozen_string_literal: true

FactoryBot.define do
  factory :tweeted_location do
    location
    place { Faker::Travel::TrainStation.name }
    text { Faker::Lorem.sentence }
    title { Faker::Book.title }
  end
end
