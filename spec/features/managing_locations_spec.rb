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
    #
    # Scenario: I search for a specific place
    #   When I enter a specific place
    #   Then it prompts me for book keywords
    #   And asks me to confirm the first matching book
    #   And adds a pin

    context 'when a Location exists, its balloon is open, and a User tags it' do
      before do
        Location.destroy_all
        Location.create author: 'Alan Moore',
                        lat_lng: ['51.519326', '-0.074316'],
                        title: 'From Hell'
        visit root_path
        find('div[role=button]').click
        click_link_or_button 'Tag'
        accept_prompt(with: 'The Ten Bells')
      end

      # rubocop:disable RSpec/NoExpectationExample
      it("the Location's tag persists") { wait_for { Location.first.reload.tags }.to eq 'The Ten Bells' }
      # rubocop:enable RSpec/NoExpectationExample
    end

    # Scenario: I delete a pin
    #   Given an open balloon
    #   When I click delete
    #   Then it asks for confirmation
    #   And deletes the pin
  end
end
