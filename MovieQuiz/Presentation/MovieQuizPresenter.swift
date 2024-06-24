import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    
    
    private let statisticService: StatisticServiceProtocol!
    weak var viewController: MovieQuizViewController?
    var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var correctAnswers = 0
    private var isButtonsEnabled = true
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        
        statisticService = StatisticService()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            correctAnswers += 1
        }
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
 /*   //метод, который содержит логику перехода в один из сценариев
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            statisticService?.store(correct: correctAnswers, total: questionsAmount)
            let bestGame = statisticService?.bestGame
            let text = """
                Ваш результат: \(correctAnswers)/\(questionsAmount)
                Количество сыгранных квизов: \(statisticService?.gamesCount ?? 0)
                Рекорд: \(bestGame?.correct ?? 0)/\(questionsAmount) (\(String(describing: bestGame?.date.dateTimeString ?? "")))
                Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? ""))%
                """
            let alertModel = AlertModel(
                title: "Этот раунд окончен!",
                message: text,
                buttonText: "Сыграть еще раз",
                completion: {
                    self.resetQuestionIndex()
                    self.correctAnswers = 0
                    self.questionFactory?.requestNextQuestion()
                })
            if let viewController = viewController {
                viewController.alertPresenter.show(in: viewController, model: alertModel)
            }
            correctAnswers = 0
        } else {
            switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    } */
    func showAnswerResult(isCorrect: Bool) {
        isButtonsEnabled = false
        didAnswer(isCorrectAnswer: isCorrect)
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        // запускаем задачу через 1 секунду c помощью диспетчера задач
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
           // код, который мы хотим вызвать через 1 секунду
            //self.presenter.questionFactory = self.questionFactory
            self.proceedToNextQuestionOrResults()
            viewController?.noBorder()
            isButtonsEnabled = true
        }
    }
    
    func proceedToNextQuestionOrResults() {
           if self.isLastQuestion() {
               let text = correctAnswers == self.questionsAmount ?
               "Поздравляем, вы ответили на 10 из 10!" :
               "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"
               
               let alertModel = AlertModel(
                   title: "Этот раунд окончен!",
                   message: text,
                   buttonText: "Сыграть ещё раз",
                   completion: {
                       self.resetQuestionIndex()
                       self.correctAnswers = 0
                       self.questionFactory?.requestNextQuestion()
                   })
               if let viewController = viewController {
                   viewController.alertPresenter.show(in: viewController, model: alertModel)
               }
           } else {
               self.switchToNextQuestion()
               questionFactory?.requestNextQuestion()
           }
       }
    
    func makeResultsMessage() -> String {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGame = statisticService.bestGame
        
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)\\\(questionsAmount)"
        let bestGameInfoLine = "Рекорд: \(bestGame.correct)\\\(bestGame.total)"
        + " (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        let resultMessage = [
            currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
        ].joined(separator: "\n")
        
        return resultMessage
    }
    
    
    
    
    // MARK: - Buttons
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard isButtonsEnabled, let currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
}


