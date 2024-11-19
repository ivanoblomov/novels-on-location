# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/ExampleLength
RSpec.describe 'Searching for Locations', :js, type: :system do
  scenario 'User searches for a Location' do
    Location.destroy_all
    Location.create title: 'The Sun Also Rises',
                    lat_lng: ['42.817422', '-1.64325']
    Location.create title: 'From Hell',
                    lat_lng: ['51.519326', '-0.074316']
    visit root_path
    fill_in 'book-input', with: Location.first.title
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
    # this must be reduced to a one-liner because only the first return-value resolves
    script = 'c = 0; Object.values(nOL.pins).forEach( (pin) => { if (pin.map) c++; } ); c;'
    pin_count = evaluate_script script
    expect(pin_count).to eq 1
  end
end
# rubocop:enable RSpec/ExampleLength
