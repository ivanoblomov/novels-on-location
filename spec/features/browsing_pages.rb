# frozen_string_literal: true

require 'rails_helper'

describe 'Browsing pages', type: :system do
  describe 'with errors' do
    around do |example|
      original_setting = Rails.application.config.consider_all_requests_local
      Rails.application.config.consider_all_requests_local = false

      begin
        example.run
      ensure
        Rails.application.config.consider_all_requests_local = original_setting
      end
    end

    describe '/locations/:non_existent' do
      it do
        visit location_path(:non_existent)
        expect(page.status_code).to eq 404
      end
    end

    describe '/' do
      it do
        allow(Location).to receive(:all).and_raise(StandardError)
        visit root_path
        expect(page.status_code).to eq 500
      end
    end
  end

  describe '/integration' do
    it do
      visit integration_path
      expect(page.status_code).to eq 200
    end
  end

  describe '/privacy' do
    it do
      visit privacy_path
      expect(page.status_code).to eq 200
    end
  end

  describe '/sitemap.xml' do
    it do
      visit '/sitemap.xml'
      expect(page.status_code).to eq 200
    end
  end
end
