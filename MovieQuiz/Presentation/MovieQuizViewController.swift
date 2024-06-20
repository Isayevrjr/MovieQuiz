import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate, AlertPresenterProtocol {
    
    
    //MARK: - Аутлеты
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    private var correctAnswers = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertDelegate: MovieQuizViewControllerDelelegate?
    private var statisticService: StatisticServiceProtocol?
    private let presenter = MovieQuizPresenter()


    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()
        
        showLoadingIndicator()
        questionFactory?.loadData()
        
        let alertDelegate = AlertPresenter()
        alertDelegate.alertController = self
        self.alertDelegate = alertDelegate
        
        
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else {
            return
        }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Private functions
    

    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        // запускаем задачу через 1 секунду c помощью диспетчера задач
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            
           // код, который мы хотим вызвать через 1 секунду
            self.showNextQuestionOrResults()
            self.noBorder()
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
        }
    }
    
 
    //метод, который содержит логику перехода в один из сценариев
    func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            statisticService?.store(correct: correctAnswers, total: presenter.questionsAmount)
                let bestGame = statisticService?.bestGame
                let text = """
Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)
Количество сыгранных квизов: \(statisticService?.gamesCount ?? 0)
Рекорд: \(bestGame?.correct ?? 0)/\(presenter.questionsAmount) (\(String(describing: bestGame?.date.dateTimeString ?? "")))
Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? ""))%
"""
                let alertModel = AlertModel(
                    title: "Этот раунд окончен!",
                    message: text,
                    buttonText: "Сыграть еще раз",
                    completion: {
                        self.presenter.resetQuestionIndex()
                        self.correctAnswers = 0
                        self.questionFactory?.requestNextQuestion()
                    })
                alertDelegate?.show(alertModel: alertModel)
                correctAnswers = 0
            } else {
                presenter.switchToNextQuestion()
                questionFactory?.requestNextQuestion()
            }
        }
    
    private func show(quiz result: QuizResultViewModel) {
        let alert = UIAlertController (
            title: result.title,
            message: result.text,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else {return}
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func noBorder() {
        imageView.layer.borderWidth = 0
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true // скрываем индикатор загрузки
          questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let model = AlertModel(
            title: "Ошибка!",
            message: message,
            buttonText: "Попробовать еще раз") { [weak self] in
                guard let self = self else { return }
                
                self.presenter.resetQuestionIndex()
                self.correctAnswers = 0
                
                self.questionFactory?.requestNextQuestion()
            }
        
        alertDelegate?.show(alertModel: model)
    
    }

    //MARK: - Кнопки
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        guard let currentQuestion else {
            return
        }
        let givenAnswer = true
        
        yesButton.isEnabled = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        guard let currentQuestion else {
            return
        }
        let givenAnswer = false
        
        noButton.isEnabled = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}
