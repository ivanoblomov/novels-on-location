# frozen_string_literal: true

require 'rails_helper'

describe 'Browsing novel Locations', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    context 'when a Location exists and a User clicks its pin' do
      before do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        title: 'From Hell'
        visit root_path
        find('div[role=button]').click
      end

      it('the map opens its balloon') { expect(page).to have_css 'div.map-balloon' }
      it('the balloon shows a Zoom button') { expect(page).to have_css 'input[value=Zoom]' }
      it('the balloon shows a Tag button') { expect(page).to have_css 'input[value=Tag]' }
      it('the balloon shows a Delete button') { expect(page).to have_css 'input[value=Delete]' }

      context 'when a User clicks Zoom' do
        before { click_button 'Zoom' }

        it('the map zooms in') { expect(evaluate_script 'nOL.map.zoom').to be > 10 }
      end
    end

    context 'when multiple Locations exist' do
      subject(:visible_pins) { evaluate_script script }

      let(:script) do
        'Object.values(nOL.pins).filter((pin) => pin.map).length;' # count visible pins (where map is defined)
      end

      before do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        tags: 'The Ten Bells, Spitalfields',
                        title: 'From Hell'
        Location.create author: 'Ernest Hemingway',
                        title: 'The Sun Also Rises',
                        lat_lng: ['42.817422', '-1.64325']
      end

      context 'when User searches for a matching author' do
        before do
          visit root_path
          fill_in 'book-input', with: 'hemingway'
        end

        it('the map hides other Locations') { expect(visible_pins).to eq 1 }
      end

      context 'when User searches for a matching title' do
        before do
          visit root_path
          fill_in 'book-input', with: 'sun also rises'
        end

        it('the map hides other Locations') { expect(visible_pins).to eq 1 }
      end

      context 'when User searches for a matching tag' do
        before do
          visit root_path
          fill_in 'book-input', with: 'ten bells'
        end

        it('the map hides other Locations') { expect(visible_pins).to eq 1 }
      end
    end
  end
end
