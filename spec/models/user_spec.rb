# frozen_string_literal: true

describe User do
  subject(:user) { User.new user_id, user_token }

  describe '#admin?' do
    context 'when User is an admin' do
      let(:user_id) { User::ADMINS.sample }
      let(:user_token) { User::ROOT_USER[1] }

      it { expect(user.admin?).to be true }
    end
  end
end
