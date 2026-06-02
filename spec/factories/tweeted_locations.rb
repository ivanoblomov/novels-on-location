# frozen_string_literal: true

FactoryBot.define do
  factory :tweeted_location do
    location
    place { 'Pennsylvania Station' }
    text { 'Conquering Gotham explores the vision and challenges faced by the Pennsylvania Railroad in constructing a monumental transit hub.' }
    title { 'Conquering Gotham' }
  end
end
