# frozen_string_literal: true

require 'rails_helper'

feature 'Browsing novel Locations', js: ENV['DRIVER'] ? ENV['DRIVER'].to_sym : :selenium_chrome_headless,
                                    type: :system do
  context 'when the map loads and a User double-clicks it' do
    let(:original_zoom_level) { evaluate_script('nOL.map.zoom') }

    it 'the map zooms in' do
      visit root_path
      wait_for { page }.to have_text 'Keyboard shortcuts'
      original_zoom_level
      find_by_id('map-canvas').double_click
      expect(evaluate_script('nOL.map.zoom')).to be >= original_zoom_level
    end
  end

  context 'when a Location exists', vcr: { cassette_name: 'when_a_location_exists' } do
    let(:from_hell) do
      Location.find_or_create_by asin: '0958578346',
                                 author: 'Alan Moore',
                                 lat_lng: ['51.519326', '-0.074316'],
                                 tags: 'The Ten Bells, Spitalfields',
                                 title: 'From Hell',
                                 user_id: '666325406'
    end

    context 'when a User clicks its pin' do
      before do
        from_hell
        visit root_path
        find('div[role=button]').click
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'the map opens its balloon' do
        expect(page).to have_css 'div.map-balloon' and expect(page).to have_no_css 'h2', text: 'null'
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "the balloon shows the novel's title as a link" do
        expect(page).to have_link 'From Hell', href: from_hell.store_url
      end

      # rubocop:disable RSpec/NoExpectationExample
      it "the balloon shows the novel's author linked to Wikipedia" do
        wait_for { page }.to have_link 'Alan Moore', href: 'https://en.wikipedia.org/wiki/Alan%20Moore'
      end
      # rubocop:enable RSpec/NoExpectationExample

      it('the balloon shows a Zoom button') { expect(page).to have_button 'Zoom' }
      it('the balloon shows an Annotate button') { expect(page).to have_button 'Annotate' }
      it('the balloon shows a Remap button') { expect(page).to have_button 'Remap' }
      it('the balloon shows a Tag button') { expect(page).to have_button 'Tag' }
      # rubocop:disable RSpec/NoExpectationExample
      it('the balloon shows a Delete button') { wait_for { page }.to have_button 'Delete' }
      # rubocop:enable RSpec/NoExpectationExample

      it "the balloon shows the novel's reader linked to Facebook" do
        pending 'Facebook integration'
        expect(page).to have_link 'Roderick Monje', href: 'https://www.facebook.com/profile.php?id=666325406'
      end

      # rubocop:disable RSpec/NoExpectationExample
      it 'the balloon shows an "All Locations for Novel" link' do
        wait_for { page }.to have_link 'All Locations for Novel'
      end
      # rubocop:enable RSpec/NoExpectationExample

      it('the balloon shows an "All Novels by Author" link') { expect(page).to have_link 'All Novels by Author' }
      it('the balloon shows an "All Pins by Reader" link') { expect(page).to have_link 'All Pins by Reader' }

      # rubocop:disable RSpec/NestedGroups
      context 'when a User clicks Zoom' do
        before { click_link_or_button 'Zoom' }

        it('the map zooms in') { expect(evaluate_script('nOL.map.zoom')).to be > 10 }
      end

      context 'when a User clicks Reload' do
        let(:count_visible_pins) do
          'Object.values(nOL.pins).filter((pin) => pin.map).length;' # count visible pins (where map is defined)
        end
        let(:visible_pins) { evaluate_script count_visible_pins }

        before { page.driver.browser.navigate.refresh }

        # rubocop:disable RSpec/MultipleExpectations
        it 'the map opens its balloon' do
          expect(page).to have_css 'div.map-balloon' and expect(page).to have_no_css 'h2', text: 'null'
        end
        # rubocop:enable RSpec/MultipleExpectations

        it('the map shows only one Location') { expect(visible_pins).to eq 1 }
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'when multiple Locations exist' do
      let(:sun_also_rises) do
        Location.find_or_create_by author: 'Ernest Hemingway',
                                   title: 'The Sun Also Rises',
                                   lat_lng: ['42.817422', '-1.64325']
      end

      before do
        from_hell
        sun_also_rises
        visit root_path
      end

      # rubocop:disable RSpec/NestedGroups
      context 'when User searches for "hemingway"' do
        before { fill_in 'book-input', with: 'hemingway' }

        it('the map hides "From Hell"') { expect(evaluate_script("nOL.pins['#{from_hell.id}'].map")).to be_nil }
      end

      context 'when User searches for "sun also rises"' do
        before { fill_in 'book-input', with: 'sun also rises' }

        it('the map hides "From Hell"') { expect(evaluate_script("nOL.pins['#{from_hell.id}'].map")).to be_nil }
      end

      context 'when User searches for "ten bells"' do
        before { fill_in 'book-input', with: 'ten bells' }

        it('the map hides "The Sun Also Rises"') {
          expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
        }
      end

      context 'when User clicks "Pins: All"' do
        before do
          original_visible_pins
          click_on 'Pins: All'
        end

        let(:count_visible_pins) do
          'Object.values(nOL.pins).filter((pin) => pin.map).length;' # count visible pins (where map is defined)
        end
        let(:original_visible_pins) { evaluate_script count_visible_pins }
        let(:visible_pins) { evaluate_script count_visible_pins }

        it("the map hides other people's Locations") { expect(visible_pins).to be < original_visible_pins }
        it('the Pins button is labeled "My Pins"') { expect(page).to have_button('Pins: My Pins') }
      end

      context 'when "From Hell"\'s balloon is open' do
        before { first('div[role=button]').click }

        context 'when the User clicks the tag "Spitalfields"' do
          before { click_link_or_button 'Spitalfields' }

          it('the map hides "The Sun Also Rises"') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end

        context 'when the User clicks "All Locations for Novel"' do
          before { click_link_or_button 'All Locations for Novel' }

          it('the map hides "The Sun Also Rises"') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end

        context 'when the User clicks "All Novels by Author"' do
          before { click_link_or_button 'All Novels by Author' }

          it('the map hides "The Sun Also Rises"') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end

        context 'when the User clicks "All Pins by Reader"' do
          before { click_link_or_button 'All Pins by Reader' }

          it('the map hides "The Sun Also Rises"') {
            expect(evaluate_script("nOL.pins['#{sun_also_rises.id}'].map")).to be_nil
          }
        end
        # rubocop:enable RSpec/NestedGroups
      end
    end
  end

  context 'when an error occurs' do
    context 'when the error is 500' do
      before { allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false) }

      it 'an alert shows the error', vcr: { cassette_name: 'an_alert_shows_the_error' } do
        pending 'a solution for a complete run (since this passes in isolation)'
        allow(Ability).to receive(:new).and_raise(StandardError, 'Mocked error for testing')
        message = accept_alert { visit root_path }
        expect(message).to eq 'Mocked error for testing'
      end
    end

    context "when a Location doesn't exist" do
      it "an alert shows the Location wasn't found",
         vcr: { cassette_name: 'an_alert_shows_the_location_wasnt_found' } do
        message = accept_alert { visit location_path(:non_existent) }
        expect(message).to eq "Sorry, that novel location doesn't exist. Why not add it?"
      end
    end
  end
end
