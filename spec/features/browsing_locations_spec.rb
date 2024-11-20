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

      # rubocop:disable RSpec/NoExpectationExample
      it('the map zooms in') { wait_for { evaluate_script('nOL.map.zoom') }.to be > original_zoom_level }
      # rubocop:enable RSpec/NoExpectationExample
    end

    context 'when a Location exists and a User clicks its pin' do
      before do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        title: 'From Hell',
                        user_id: '666325406'
        visit root_path
        find('div[role=button]').click
      end

      it('the map opens its balloon') { expect(page).to have_css 'div.map-balloon' }
      it('the balloon shows a Zoom button') { expect(page).to have_css 'input[value=Zoom]' }
      it('the balloon shows a Annotate button') { expect(page).to have_css 'input[value=Annotate]' }
      it('the balloon shows a Remap button') { expect(page).to have_css 'input[value=Remap]' }
      it('the balloon shows a Tag button') { expect(page).to have_css 'input[value=Tag]' }
      it('the balloon shows a Delete button') { expect(page).to have_css 'input[value=Delete]' }
      it('the balloon shows a All Locations for Novel button') { expect(page).to have_link 'All Locations for Novel' }
      it('the balloon shows a All Novels by Author button') { expect(page).to have_link 'All Locations for Novel' }
      it('the balloon shows a All Pins by Reader button') { expect(page).to have_link 'All Pins by Reader' }

      context 'when a User clicks Zoom' do
        before { click_link_or_button 'Zoom' }

        it('the map zooms in') { expect(evaluate_script('nOL.map.zoom')).to be > 10 }
      end
    end

    context 'when multiple Locations exist' do
      let(:from_hell) do
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        tags: 'The Ten Bells, Spitalfields',
                        title: 'From Hell',
                        user_id: '666325406'
      end
      let(:script) do
        'Object.values(nOL.pins).filter((pin) => pin.map).length;' # count visible pins (where map is defined)
      end
      let(:sun_also_rises) do
        Location.create author: 'Ernest Hemingway',
                        title: 'The Sun Also Rises',
                        lat_lng: ['42.817422', '-1.64325']
      end

      before do
        Location.destroy_all
        from_hell
        sun_also_rises
        visit root_path
      end

      context 'when User searches for a matching author' do
        before { fill_in 'book-input', with: 'hemingway' }

        it('the map hides From Hell') { expect(evaluate_script("nOL.pins['#{from_hell.id}'].map")).to be_nil }
      end

      context 'when User searches for a matching title' do
        before { fill_in 'book-input', with: 'sun also rises' }

        it('the map hides From Hell') { expect(evaluate_script("nOL.pins['#{from_hell.id}'].map")).to be_nil }
      end

      context 'when User searches for a matching tag' do
        before { fill_in 'book-input', with: 'ten bells' }

        it('the map hides The Sun Also Rises') {
          expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
        }
      end

      context 'when User clicks Pins: All' do
        before do
          original_visible_pins
          click_on 'Pins: All'
        end

        let(:original_visible_pins) { evaluate_script script }
        let(:visible_pins) { evaluate_script script }

        it("the map hides other people's Locations") { expect(visible_pins).to be < original_visible_pins }
        it('the Pins button is labeled My Pins') { expect(page).to have_selector(:link_or_button, 'Pins: My Pins') }
      end

      context "when a Location's balloon is open" do
        before do
          first('div[role=button]').click
        end

        context 'when the User clicks All Locations for Novel' do
          before { click_link_or_button 'All Locations for Novel' }

          it('the map hides The Sun Also Rises') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end
      end
    end
  end
end

        context 'when the User clicks All Novels by Author' do
          before { click_link_or_button 'All Novels by Author' }

          it('the map hides The Sun Also Rises') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end

        context 'when the User clicks All Pins by Reader' do
          before { click_link_or_button 'All Pins by Reader' }

          it('the map hides The Sun Also Rises') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end
