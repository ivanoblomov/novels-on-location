# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'routes' do
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

    describe '/locations/1' do
      it do
        get location_path(1)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '/integration' do
    it do
      get integration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe '/privacy' do
    it do
      get privacy_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe '/sitemap.xml' do
    it do
      get sitemap_path, headers: { 'ACCEPT' => 'application/xml' }
      expect(response).to have_http_status(:ok)
    end
  end
end
