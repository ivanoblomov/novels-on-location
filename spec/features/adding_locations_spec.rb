# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Novels: On Location', js: !ENV['GITHUB_ACTIONS'], type: :system do
  if ENV['GITHUB_ACTIONS']
    pending 'Disabling JavaScript on CI until Selenium bug is fixed: https://github.com/SeleniumHQ/selenium/issues/14609'
  else
#     Scenario: I add a pin
#       Given it's in write mode
#       When I double-click the map
#       Then it prompts me for book keywords
#       And asks me to confirm the first matching book
#       And adds a pin
#
#     Scenario: I search for a specific place
#       When I enter a specific place
#       Then it prompts me for book keywords
#       And asks me to confirm the first matching book
#       And adds a pin
#
#     Scenario: I click a pin
#       Given a pin
#       When I click it
#       Then a ballloon opens
#       And I should see a zoom, tag, and delete button
#
#     Scenario: I zoom a pin
#       Given an open balloon
#       When I click zoom
#       Then it should increase the zoom level
#
#     Scenario: I tag a pin
#       Given an open balloon
#       When I click tag
#       Then it should prompt me for keywords
#       And add the tag
#
#     Scenario: I delete a pin
#       Given an open balloon
#       When I click delete
#       Then it asks for confirmation
#       And deletes the pin
  end
end
