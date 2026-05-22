# frozen_string_literal: true

require 'rails_helper'

describe 'Map-less pages' do
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
