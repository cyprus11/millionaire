FactoryBot.define do
  factory :game_question do
    # всегда одинаковое распределение ответов
    a { 4 }
    b { 3 }
    c { 2 }
    d { 1 }

    # Связь с игрой и вопросом.
    # Если при создании game_question не указать явно объекты Игра и Вопрос,
    # наша фабрика сама создаст и пропишет нужные объекты, используя фабрики
    # с именами :game и :question
    association :game
    association :question
  end

  factory :game do
    # связь с юзером
    association :user

    #  игра только начата
    finished_at { nil }
    current_level { 0 }
    is_failed { false }
    prize { 0 }
    # ! эта фабрика создает объект Game без дочерних игровых вопросов,
    # в такую игру играть нельзя, расширим фабрику дочерней фабрикой!

    # фабрика наследует все поля от фабрики :game
    factory :game_with_questions do
      # коллбэк после :build игры - создаем 15 вопросов
      after(:build) { |game|
        15.times do |i|
          # factory_girl create - дергает соотв. фабрику
          # создаем явно вопрос с нужным уровнем
          q = create(:question, level: i)
          # создаем связанные game_questions с нужной игрой и вопросом
          create(:game_question, game: game, question: q)
        end
      }
    end
  end

  factory :question do
    # Ответы сделаем рандомными для красоты
    answer1 { "#{rand(2001)}" }
    answer2 { "#{rand(2001)}" }
    answer3 { "#{rand(2001)}" }
    answer4 { "#{rand(2001)}" }

    sequence(:text) { |n| "В каком году была космическая одиссея #{n}?" }

    sequence(:level) { |n| n % 15 }
  end

  factory :user do
    # генерим рандомное имя
    name { "Жора_#{rand(999)}" }

    # email должен быть уникален - при каждом вызове фабрики n будет увеличен поэтому все юзеры
    # будут иметь разные адреса: someguy_1@example.com, someguy_2@example.com, someguy_3@example.com ...
    sequence(:email) { |n| "someguy_#{n}@example.com" }

    # всегда создается с флажком false, ничего не генерим
    is_admin { false }

    # всегда нулевой
    balance { 0 }

    # коллбэк - после фазы :build записываем поля паролей, иначе Devise не позволит :create юзера
    after(:build) { |u| u.password_confirmation = u.password = "123456" }
  end
end
