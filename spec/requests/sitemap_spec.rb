# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'routes' do
  describe '/sitemap.xml' do
    it do
      get sitemap_path, headers: { 'ACCEPT' => 'application/xml' }
      expect(response).to have_http_status(:ok)
    end
  end
end
