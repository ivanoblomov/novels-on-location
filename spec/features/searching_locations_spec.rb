# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Searching for Locations', :js, type: :system do
  scenario 'User searches for a Location' do
    visit root_path
    fill_in '#book-input', with: Location.first.title
    # should hide all other pins
  end
end
