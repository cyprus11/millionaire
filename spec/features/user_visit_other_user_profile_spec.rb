require 'rails_helper'

RSpec.feature 'USER visit other user profile', type: :feature do
  let(:games) { create_list(:game, 2, prize: 100) }

  let(:user) { create(:user) }
  let(:other_user) { create(:user, name: 'Василий', games: games) }

  before do
    login_as user
  end

  scenario 'visit other profile' do
    visit user_path(other_user)

    expect(page).to have_current_path "/users/#{other_user.id}"
    expect(page).not_to have_content "Сменить имя и пароль"
    expect(page).to have_content I18n.l(Time.now, format: :short)
    expect(page).to have_content 100
  end
end
