# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Managing Locations', js: ENV['DRIVER'] ? ENV['DRIVER'].to_sym : :selenium_chrome_headless,
                                     type: :system do
  context 'when the map is in "Add Pins" mode and a User double-clicks it and enters keywords' do
    before do
      visit root_path
      click_on 'Mode: Zoom'
      execute_script 'nOL.promptForBook(new google.maps.LatLng(51.519326, -.074316))' # HACK: since double-click fails
      accept_confirm { accept_prompt with: 'from hell alan moore' }
    end

    # rubocop:disable-next RSpec/NoExpectationExample
    it('the Location is created', vcr: { cassette_name: 'the_location_is_created' }) {
      wait_for do
        Location.count
      end.to eq 1
    }
  end

  context 'when a User enters a specific place, keywords for the book, and some notes',
          vcr: { cassette_name: 'when_a_user_enters_a_specific_place_keywords_for_the_book_and_some_notes' } do
    before do
      visit root_path
      fill_in 'place-input', with: "san sebastian\n"
      accept_prompt(with: 'sun also rises')
      accept_confirm
      accept_prompt(with: 'a swim after rejection')
    end

    it('the Location is created') { expect(Location.count).to eq 1 }
  end

  context 'when a Location exists and a User drags its pin to a new place',
          vcr: { cassette_name: 'when_a_location_exists_and_a_user_drags_its_pin_to_a_new_place' } do
    let(:la_concha) do
      pending 'a working alternative to drag_to'
      Location.find_or_create_by author: 'Ernest Hemingway',
                                 lat_lng: ['43.3186188', '-1.9860118'],
                                 title: 'The Sun Also Rises'
    end
    let(:pins) { all('div[role=button]') }
    let(:the_ritz) do
      Location.find_or_create_by author: 'Ernest Hemingway',
                                 lat_lng: ['40.4157577', '-3.692606699999999'],
                                 title: 'The Sun Also Rises'
    end

    before do
      la_concha
      the_ritz
      visit root_path
      source = pins[0]
      target = pins[1]
      accept_confirm { source.drag_to target }
    end

    # rubocop:disable-next RSpec/NoExpectationExample
    it "the Location's new coordinates persist" do
      wait_for { la_concha.reload.lat_lng[0].to_f }.to be_within(0.1).of(the_ritz.reload.lat_lng[0].to_f) and
        wait_for { la_concha.reload.lat_lng[1].to_f }.to be_within(0.1).of(the_ritz.reload.lat_lng[1].to_f)
    end
  end

  context 'when a Location exists and its balloon is open',
          vcr: { cassette_name: 'when_a_location_exists_and_its_balloon_is_open' } do
    before do
      Location.find_or_create_by author: 'Alan Moore',
                                 lat_lng: ['51.519326', '-0.074316'],
                                 title: 'From Hell'
      visit root_path
      find('div[role=button]').click
    end

    context 'when a User annotates it' do
      before { accept_prompt(with: 'Originally serialized in Taboo') { click_link_or_button 'Annotate' } }

      # rubocop:disable-next RSpec/NoExpectationExample
      it("the Location's note persists") {
        wait_for { Location.first.reload.notes }.to eq 'Originally serialized in Taboo'
      }
    end

    context 'when a User remaps it' do
      before do
        original_coordinates
        accept_prompt(with: '1 Highbury Place, Islington') { click_link_or_button 'Remap' }
      end

      let(:original_coordinates) { Location.first.lat_lng }

      # rubocop:disable-next RSpec/NoExpectationExample
      it("the Location's new coordinates persist") do
        wait_for { Location.first.reload.lat_lng }.not_to eq original_coordinates
      end
    end

    context 'when a User tags it' do
      before { accept_prompt(with: 'The Ten Bells') { click_link_or_button 'Tag' } }

      # rubocop:disable-next RSpec/NoExpectationExample
      it("the Location's tag persists") { wait_for { Location.first.reload.tags }.to eq 'The Ten Bells' }
    end

    context 'when a User deletes it' do
      before do
        click_link_or_button 'Delete'
        accept_confirm
      end

      # rubocop:disable-next RSpec/NoExpectationExample
      it('the Location no longer exists') { wait_for { Location.count }.to eq 0 }
    end
  end
end
