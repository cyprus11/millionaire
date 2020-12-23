# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do

    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it "return correct count of money" do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      b = user.balance

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на 2 уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # забираем деньги
      game_w_questions.take_money!

      # проверяем что игра закончилась
      expect(game_w_questions.finished?).to be_truthy

      # проверяем что пользователь получил деньги
      expect(user.balance).to eq(b + game_w_questions.prize)
    end
  end

  describe 'status' do
    context 'status method' do
      before(:each) do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions.finished?).to be_truthy
      end

      it ':fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end

      it ':timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end

      it ':won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end

      it ':money' do
        expect(game_w_questions.status).to eq(:money)
      end
    end
  end

  describe 'current_game_question' do
    context 'current game question' do
      it 'current question' do
        game_w_questions.current_level = 5
        expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[game_w_questions.current_level])
      end
    end
  end

  describe 'previous_level' do
    context 'previous level' do
      it 'prev level' do
        game_w_questions.current_level = 10
        expect(game_w_questions.previous_level).to eq(9)
      end

      it 'new game' do
        expect(game_w_questions.previous_level).to eq(-1)
      end

      it 'when game finished' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.previous_level).to eq(Question::QUESTION_LEVELS.max)
      end
    end
  end

  describe 'answer_current_question!' do
    let(:right_answer) { game_w_questions.game_questions[game_w_questions.current_level].correct_answer_key }

    context 'when time out or game finished' do
      it 'return false' do
        game_w_questions.created_at = 35.minutes.ago

        expect(game_w_questions.answer_current_question!(right_answer)).to eq(false)
        expect(game_w_questions.status).to eq(:timeout)
        expect(game_w_questions.finished?).to eq(true)
      end
    end

    context 'when answer right' do
      context 'and game in progress' do
        it 'return true' do
          current_level = game_w_questions.current_level
          game_w_questions.created_at = Time.now

          expect(game_w_questions.answer_current_question!(right_answer)).to eq(true)
          expect(game_w_questions.current_level).to eq(current_level + 1)
          expect(game_w_questions.status).to eq(:in_progress)
        end
      end

      context 'and current level last' do
        it 'return true when answer right' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max

          expect(game_w_questions.answer_current_question!(right_answer)).to eq(true)
          expect(game_w_questions.status).to eq(:won)
          expect(game_w_questions.finished?).to eq(true)
          expect(game_w_questions.prize).to eq(Game::PRIZES[Question::QUESTION_LEVELS.max])
        end
      end
    end

    context 'when answer wrong' do
      let(:wrong_answer) { 'wrong answer' }

      context 'and question is last' do
        it 'return false and status fail' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max

          expect(game_w_questions.answer_current_question!(wrong_answer)).to eq(false)
          expect(game_w_questions.current_level).to eq(Question::QUESTION_LEVELS.max)
          expect(game_w_questions.status).to eq(:fail)
          expect(game_w_questions.finished?).to eq(true)
        end
      end

      it 'return false and game finish' do
        expect(game_w_questions.answer_current_question!(wrong_answer)).to eq(false)
        expect(game_w_questions.status).to eq(:fail)
        expect(game_w_questions.finished?).to eq(true)
      end
    end
  end
end
