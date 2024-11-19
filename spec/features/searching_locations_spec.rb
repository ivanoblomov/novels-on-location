# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/ExampleLength
RSpec.describe 'Searching for Locations', js: !ENV['GITHUB_ACTIONS'], type: :system do
  scenario 'User searches for a Location' do
    if ENV['GITHUB_ACTIONS']
      pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
      raise
    else
      Location.destroy_all
      Location.create title: 'The Sun Also Rises',
                      lat_lng: ['42.817422', '-1.64325']
      Location.create title: 'From Hell',
                      lat_lng: ['51.519326', '-0.074316']
      visit root_path
      fill_in 'book-input', with: Location.first.title
      # count visible pins (where map is defined)
      script = 'Object.values(nOL.pins).filter((pin) => pin.map).length;'
      pin_count = evaluate_script script
      expect(pin_count).to eq 1
    end
  end
end
# rubocop:enable RSpec/ExampleLength
