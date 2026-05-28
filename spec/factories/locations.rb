# frozen_string_literal: true

FactoryBot.define do
  factory :location do
    lat_lng { ['42.817422', '-1.64325'] }
    title { Faker::Book.title }
  end

  trait :location_matching_coordinates do
    lat_lng { ['42.817422', '-1.64325'] }
    title { Faker::Book.title }
  end
end
