# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq({ 'a' => game_question.question.answer2,
                                             'b' => game_question.question.answer1,
                                             'c' => game_question.question.answer4,
                                             'd' => game_question.question.answer3 })
    end

    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  context 'validations check' do
    it "be equal" do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  context 'correct answer key' do
    it 'be correct' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  context 'help methods' do
    describe '#fifty_fifty' do
      it 'fills in help hash with 50 / 50 questions' do
        expect(game_question.help_hash).not_to include(:fifty_fifty)
        game_question.add_fifty_fifty

        expect(game_question.help_hash).to include(:fifty_fifty)
        ff = game_question.help_hash[:fifty_fifty]

        expect(ff).to include('b')
        expect(ff.size).to eq 2
      end
    end

    describe '#audience_help' do
      it 'fills in help hash with audience choices' do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.add_audience_help

        expect(game_question.help_hash).to include(:audience_help)

        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end

    describe '#friend_call' do
      it 'fills in help hash with friend opinion' do
        expect(game_question.help_hash).not_to include(:friend_call)

        game_question.add_friend_call

        expect(game_question.help_hash).to include(:friend_call)

        fc = game_question.help_hash[:friend_call]
        expect(fc).to match(/считает, что это вариант/)
      end
    end
  end
end
