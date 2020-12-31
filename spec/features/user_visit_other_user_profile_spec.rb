require 'rails_helper'

RSpec.feature 'USER visit other user profile', typre: :feature do
  let(:games) do
    (1..2).to_a.map do |i|
      create(:game,
             prize: i * 100)
    end
  end

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
    expect(page).to have_content i * 2
  end
end
