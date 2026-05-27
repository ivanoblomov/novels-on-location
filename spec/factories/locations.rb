# frozen_string_literal: true

FactoryBot.define do
  factory :location do
    id { 1 }
    lat_lng { ['42.817422', '-1.64325'] }
  end
end
