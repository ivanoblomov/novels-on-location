# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Novels: On Location', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    context 'when multiple Locations exist' do
      let(:sun_also_rises) do
        Location.destroy_all
        Location.create title: 'From Hell',
                        lat_lng: ['51.519326', '-0.074316']
        Location.create title: 'The Sun Also Rises',
                        lat_lng: ['42.817422', '-1.64325']
      end

      context 'when User searches for a specific Location' do
        subject(:visible_pins) do
          # count visible pins (where map is defined)
          script = 'Object.values(nOL.pins).filter((pin) => pin.map).length;'
          evaluate_script script
        end

        before do
          visit root_path
          fill_in 'book-input', with: sun_also_rises.title
        end

        it('hides other Locations') { expect(visible_pins).to eq 1 }
      end
    end
  end
end
