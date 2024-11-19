# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Novels: On Location', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    context 'when multiple Locations exist' do
      subject(:visible_pins) { evaluate_script script }

      let(:script) do
        'Object.values(nOL.pins).filter((pin) => pin.map).length;' # count visible pins (where map is defined)
      end
      let(:sun_also_rises) do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        tags: 'The Ten Bells, Spitalfields',
                        title: 'From Hell'
        Location.create author: 'Ernest Hemingway',
                        title: 'The Sun Also Rises',
                        lat_lng: ['42.817422', '-1.64325']
      end

      context 'when User searches for an author' do
        before do
          visit root_path
          fill_in 'book-input', with: sun_also_rises.author
        end

        it('hides other Locations') { expect(visible_pins).to eq 1 }
      end

      context 'when User searches for a title' do
        before do
          visit root_path
          fill_in 'book-input', with: sun_also_rises.title
        end

        it('hides other Locations') { expect(visible_pins).to eq 1 }
      end

      context 'when User searches for a tag' do
        before do
          visit root_path
          fill_in 'book-input', with: 'ten bells'
        end

        it('hides other Locations') { expect(visible_pins).to eq 1 }
      end
    end
  end
end
