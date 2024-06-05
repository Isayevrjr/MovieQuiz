import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate, AlertPresenterProtocol {
    
    //MARK: - Аутлеты
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    
    // MARK: - Lifecycle
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private var questionAmount = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertDelegate: MovieQuizViewControllerDelelegate?
    private var statisticService: StatisticServiceProtocol?


    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statisticService = StatisticService()
        
        let questionFactory = QuestionFactory()
        questionFactory.delegate = self
        self.questionFactory = questionFactory
        
        questionFactory.requestNextQuestion()
        
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
        let viewModel = convert(model: question)
        
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Private functions
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionAmount)")
        
        return questionStep
    }
    
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
        imageView.layer.cornerRadius = 6
        
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
            if currentQuestionIndex == questionAmount - 1 {
                statisticService?.store(correct: correctAnswers, total: questionAmount)
                let bestGame = statisticService?.bestGame
                let text = """
Ваш результат: \(correctAnswers)/\(questionAmount)
Количество сыгранных квизов: \(statisticService?.gamesCount ?? 0)
Рекорд: \(bestGame?.correct ?? 0)/\(questionAmount) (\(String(describing: bestGame?.date.dateTimeString ?? "")))
Средняя точность: \(String(format: "%.2f", statisticService?.totalAccuracy ?? ""))%
"""
                let alertModel = AlertModel(
                    title: "Этот раунд закончен",
                    message: text,
                    buttonText: "Сыграть еще раз",
                    completion: {
                        self.currentQuestionIndex = 1
                        self.correctAnswers = 0
                        self.questionFactory?.requestNextQuestion()
                    })
                alertDelegate?.show(alertModel: alertModel)
                correctAnswers = 0
            } else {
                currentQuestionIndex += 1
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
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func noBorder() {
        imageView.layer.borderWidth = 0
    }

    //MARK: - Кнопки
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        guard let currentQuestion else {
            return
        }
        let givenAnswer = true
        
        yesButton.isEnabled = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnwer)
        
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        guard let currentQuestion else {
            return
        }
        let givenAnswer = false
        
        noButton.isEnabled = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnwer)
    }
}
