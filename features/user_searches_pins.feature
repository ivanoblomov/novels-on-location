@javascript
Feature: User searches pins

  As a user
  I want to search pins
  So that people will know where a book took place or what books took place somewhere

  Scenario: Visitor searches for a location
    Given multiple pins
    When I search for keywords matching one of their locations
    Then it should hide all the other pins

  Scenario: Visitor searches for an author
    Given multiple pins
    When I search for an author matching one of their books
    Then it should hide all the other pins

  Scenario: Visitor searches for a title
    Given multiple pins
    When I search for a title matching one of their books
    Then it should hide all the other pins

  Scenario: Visitor searches for a tag
    Given multiple pins
    When I search for a tag matching one of them
    Then it should hide all the other pins
