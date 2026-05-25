# frozen_string_literal: true

require 'rails_helper'

describe 'Mapless pages' do
  context 'with invalid host' do
    before { host! 'not-localhost' }

    it do
      get '/'
      expect(response).to redirect_to "https://#{Rails.application.config.main_host}"
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
