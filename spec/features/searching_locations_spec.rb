require 'rails_helper'

RSpec.feature 'Searching for Locations', type: :feature do
  scenario 'User searches for a Location' do
    visit root_path
    fill_in '#book-input', with: Location.first.title
    # should hide all other pins
  end
end
