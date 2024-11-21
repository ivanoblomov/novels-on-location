# frozen_string_literal: true

require 'rails_helper'

describe 'Browsing novel Locations', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    let(:from_hell) do
      Location.find_or_create_by asin: '0958578346',
                                 author: 'Alan Moore',
                                 lat_lng: ['51.519326', '-0.074316'],
                                 tags: 'The Ten Bells, Spitalfields',
                                 title: 'From Hell',
                                 user_id: '666325406'
    end

    context 'when the map loads and a User double-clicks it' do
      let(:original_zoom_level) { evaluate_script('nOL.map.zoom') }

      it 'the map zooms in' do
        visit root_path
        wait_for { page }.to have_content 'Keyboard shortcuts'
        original_zoom_level
        find_by_id('map-canvas').double_click
        expect(evaluate_script('nOL.map.zoom')).to be > original_zoom_level
      end
    end

    context 'when a Location exists and a User clicks its pin' do
      before do
        Location.destroy_all
        from_hell
        visit root_path
        find('div[role=button]').click
      end

      it('the map opens its balloon') { expect(page).to have_css 'div.map-balloon' }

      it "the balloon shows the novel's title linked to Amazon" do
        expect(page).to have_link 'From Hell', href: from_hell.amazon_url
      end

      it "the balloon shows the novel's author linked to Wikipedia" do
        expect(page).to have_link 'Alan Moore', href: 'http://en.wikipedia.org/wiki/Alan%20Moore'
      end

      it('the balloon shows a Zoom button') { expect(page).to have_button 'Zoom' }
      it('the balloon shows an Annotate button') { expect(page).to have_button 'Annotate' }
      it('the balloon shows a Remap button') { expect(page).to have_button 'Remap' }
      it('the balloon shows a Tag button') { expect(page).to have_button 'Tag' }
      it('the balloon shows a Delete button') { expect(page).to have_button 'Delete' }
      it('the balloon shows a "Buy from Amazon" link') { expect(page).to have_link href: from_hell.amazon_url }

      it "the balloon shows the novel's reader linked to Facebook" do
        pending 'Facebook integration'
        expect(page).to have_link 'Roderick Monje', href: 'http://www.facebook.com/profile.php?id=666325406'
      end

      it 'the balloon shows an "All Locations for Novel" link' do
        expect(page).to have_link 'All Locations for Novel'
      end

      it('the balloon shows an "All Novels by Author" link') { expect(page).to have_link 'All Novels by Author' }
      it('the balloon shows an "All Pins by Reader" link') { expect(page).to have_link 'All Pins by Reader' }

      context 'when a User clicks Zoom' do
        before { click_link_or_button 'Zoom' }

        it('the map zooms in') { expect(evaluate_script('nOL.map.zoom')).to be > 10 }
      end
    end

    context 'when multiple Locations exist' do
      let(:sun_also_rises) do
        Location.find_or_create_by author: 'Ernest Hemingway',
                                   title: 'The Sun Also Rises',
                                   lat_lng: ['42.817422', '-1.64325']
      end

      before do
        Location.destroy_all
        from_hell
        sun_also_rises
        visit root_path
      end

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
      end
    end
  end
end
