# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Managing Locations', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
    # Scenario: I add a pin
    #   Given it's in write mode
    #   When I double-click the map
    #   Then it prompts me for book keywords
    #   And asks me to confirm the first matching book
    #   And adds a pin

    context 'when a User enters a specific place and keywords for the book' do
      before do
        Location.destroy_all
        visit root_path
        fill_in 'place-input', with: "san sebastian\n"
        accept_prompt(with: 'sun also rises')
        accept_alert
        pending
      end

      it('the Location is created') { expect(Location.count).to eq 1 }
    end

    context 'when a Location exists and its balloon is open' do
      before do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        title: 'From Hell'
        visit root_path
        find('div[role=button]').click
      end

      context 'when a User tags it' do
        before do
          click_link_or_button 'Tag'
          accept_prompt(with: 'The Ten Bells')
        end

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
