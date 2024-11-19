# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Novels: On Location', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    context 'when a Location exists and User clicks its pin' do
      before do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        title: 'From Hell'
        visit root_path
        find('div[role=button]').click
      end

      it { expect(page).to have_css 'div.map-balloon' }
      it { expect(page).to have_css 'input[value=Zoom]' }
      it { expect(page).to have_css 'input[value=Tag]' }
      it { expect(page).to have_css 'input[value=Delete]' }
    end

    # Scenario: I zoom a pin
    #   Given an open balloon
    #   When I click zoom
    #   Then it should increase the zoom level
    #
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

      context 'when User searches for an author' do
        before do
          visit root_path
          fill_in 'book-input', with: 'hemingway'
        end

        it('hides other Locations') { expect(visible_pins).to eq 1 }
      end

      context 'when User searches for a title' do
        before do
          visit root_path
          fill_in 'book-input', with: 'sun also rises'
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
