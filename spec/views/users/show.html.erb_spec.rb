require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:current_user) { create(:user, name: 'Алексий', balance: 1000) }

  context 'when users see his profile' do
    before do
      assign(:user, current_user)
      assign(:games, [build_stubbed(:game)])

      sign_in current_user
      stub_template "users/_game.html.erb" => "User game"

      render
    end

    it 'render users name' do
      expect(rendered).to match('Алексий')
    end

    it 'render change password button in users profile for profile owner' do
      expect(rendered).to match('Сменить имя и пароль')
    end

    it 'renders game partial' do
      expect(rendered).to have_content "User game"
    end
  end

  context 'when user check other profile' do
    before do
      assign(:user, current_user)
      assign(:games, [build_stubbed(:game)])

      stub_template "users/_game.html.erb" => "User game"

      render
    end

    it 'does not render change password button if users are not in his profile' do
      expect(rendered).not_to match('Сменить имя и пароль')
    end

    it 'renders game partial' do
      expect(rendered).to have_content "User game"
    end
  end
end
