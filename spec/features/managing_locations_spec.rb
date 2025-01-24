# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Managing Locations', js: :selenium_chrome_headless, type: :system do
  if false
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    context 'when the map is in "Add Pins" mode and a User double-clicks it and enters keywords' do
      before do
        Location.destroy_all
        visit root_path
        click_on 'Mode: Zoom'
        execute_script 'nOL.promptForBook(new google.maps.LatLng(51.519326, -.074316))' # HACK: since double-click fails
        accept_prompt with: 'from hell alan moore'
        accept_confirm
      end

      # rubocop:disable RSpec/NoExpectationExample
      it('the Location is created') { wait_for { Location.count }.to eq 1 }
      # rubocop:enable RSpec/NoExpectationExample
    end

    context 'when a User enters a specific place, keywords for the book, and some notes' do
      before do
        Location.destroy_all
        visit root_path
        fill_in 'place-input', with: "san sebastian\n"
        accept_prompt(with: 'sun also rises')
        accept_confirm
        accept_prompt(with: 'a swim after rejection')
      end

      it('the Location is created') { expect(Location.count).to eq 1 }
    end

    context 'when a Location exists and its balloon is open' do
      before do
        Location.destroy_all
        Location.find_or_create_by author: 'Alan Moore',
                                   lat_lng: ['51.519326', '-0.074316'],
                                   title: 'From Hell'
        visit root_path
        find('div[role=button]').click
      end

      context 'when a User annotates it' do
        before { accept_prompt(with: 'Originally serialized in Taboo') { click_link_or_button 'Annotate' } }

        # rubocop:disable RSpec/NoExpectationExample
        it("the Location's note persists") {
          wait_for { Location.first.reload.notes }.to eq 'Originally serialized in Taboo'
        }
        # rubocop:enable RSpec/NoExpectationExample
      end

      context 'when a User remaps it' do
        before do
          original_coordinates
          accept_prompt(with: '1 Highbury Place, Islington') { click_link_or_button 'Remap' }
        end

        let(:original_coordinates) { Location.first.lat_lng }

        # rubocop:disable RSpec/NoExpectationExample
        it("the Location's new coordinates persist") do
          wait_for { Location.first.reload.lat_lng }.not_to eq original_coordinates
        end
        # rubocop:enable RSpec/NoExpectationExample
      end

      context 'when a User tags it' do
        before { accept_prompt(with: 'The Ten Bells') { click_link_or_button 'Tag' } }

        # rubocop:disable RSpec/NoExpectationExample
        it("the Location's tag persists") { wait_for { Location.first.reload.tags }.to eq 'The Ten Bells' }
        # rubocop:enable RSpec/NoExpectationExample
      end

      context 'when a User deletes it' do
        before do
          click_link_or_button 'Delete'
          accept_confirm
        end

        # rubocop:disable RSpec/NoExpectationExample
        it('the Location no longer exists') { wait_for { Location.count }.to eq 0 }
        # rubocop:enable RSpec/NoExpectationExample
      end
    end
  end
end
