# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'routes' do
  describe 'GET /sitemap.xml' do
    it 'returns a successful response' do
      get sitemap_path, headers: { 'ACCEPT' => 'application/xml' }
      expect(response).to have_http_status(:ok)
    end
  end
end
