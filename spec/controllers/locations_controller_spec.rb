# frozen_string_literal: true

require 'rails_helper'

describe LocationsController do
  let(:location) { instance_spy(Location) }
  let(:user) { instance_double(User, id: 1) }

  it 'DELETE unbookmark' do
    allow(User).to receive(:new).and_return(user)
    allow(Location).to receive(:find).and_return(location)
    delete :unbookmark, format: :json, params: { id: 1 }
    expect(location).to have_received(:remove_bookmark).with(user.id)
  end
end
