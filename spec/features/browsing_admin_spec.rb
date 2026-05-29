# frozen_string_literal: true

require 'rails_helper'

feature 'Browsing Locations in admin', js: ENV['DRIVER'] ? ENV['DRIVER'].to_sym : :selenium_chrome_headless,
                                       type: :system do
  context 'when Locations exist' do
    let(:from_hell) { build(:location, :from_hell) }
    let(:sun_also_rises) { build(:location, :sun_also_rises) }

    before do
      Location.delete_all
      from_hell.save
      sun_also_rises.save
      visit admin_locations_path
    end

    it { expect(page).to have_text 'Novels: On Location - 2 Novels/2 Locations' }

    context 'when the User clicks "Duplicate?"' do
      before { click_link 'Duplicate?' }

      it { expect(page).to have_current_path(admin_locations_path(by: 'duplicate?', dir: 'asc')) }

      # rubocop:disable RSpec/NestedGroups
      context 'when the User clicks "Duplicate?" again' do
        before { click_link 'Duplicate?' }

        it { expect(page).to have_current_path(admin_locations_path(by: 'duplicate?', dir: 'desc')) }
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end
end
