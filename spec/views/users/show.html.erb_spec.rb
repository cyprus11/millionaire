require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'when users in his profile' do
    before(:each) do
      assign(:user, build_stubbed(:user, name: 'Алексий', balance: 1000))
    end

    it 'render users name' do
      render

      expect(rendered).to match('Алексий')
    end

    it 'render change password button in users profile for profile owner' do
      current_user = assign(:user, build_stubbed(:user, name: 'Алексий', balance: 1000))
      allow(view).to receive(:current_user).and_return(current_user)

      render
      expect(rendered).to match('Сменить имя и пароль')
    end

    it 'does not render change password button if users are not in his profile' do
      render

      expect(rendered).not_to match('Сменить имя и пароль')
    end

    it 'renders game partial' do
      stub_template("users/_game.html.erb" => "User game")

      render
      # binding.irb
      expect(rendered).to have_content "User game"
    end
  end
end
