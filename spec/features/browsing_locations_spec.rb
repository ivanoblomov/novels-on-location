# frozen_string_literal: true

require 'rails_helper'

describe 'Browsing novel Locations', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    context 'when the map loads and a User double-clicks it' do
      before do
        visit root_path
        using_wait_time(2) { original_zoom_level }
        find_by_id('map-canvas').double_click
      end

      let(:original_zoom_level) { evaluate_script('nOL.map.zoom') }

      it('the map zooms in') { wait_for { evaluate_script('nOL.map.zoom') }.to be > original_zoom_level }
    end

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
        before { click_link_or_button 'Zoom' }

        it('the map zooms in') { expect(evaluate_script('nOL.map.zoom')).to be > 10 }
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

      context 'when User clicks Pins: All' do
        before do
          visit root_path
          original_visible_pins
          click_on 'Pins: All'
        end

        let(:original_visible_pins) { evaluate_script script }

        it("the map hides other people's Locations") { expect(visible_pins).to be < original_visible_pins }
        it('the Pins button is labeled My Pins') { expect(page).to have_selector(:link_or_button, 'Pins: My Pins') }
      end
    end
  end
end
