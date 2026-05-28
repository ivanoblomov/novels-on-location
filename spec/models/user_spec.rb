# frozen_string_literal: true

describe User do
  subject(:user) { described_class.new user_id, user_token }

  let(:user_id) { Faker::IdNumber }
  let(:user_token) { Faker::IdNumber }

  describe '#admin?' do
    context 'when User is an admin' do
      let(:user_id) { User::ADMINS.sample }

      it { expect(user.admin?).to be true }
    end

    context "when User isn't an admin" do
      it { expect(user.admin?).to be false }
    end
  end
end
