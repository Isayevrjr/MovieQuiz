import UIKit

final class MovieQuizViewController: UIViewController {
    
    
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
    
    private var alertDelegate: MovieQuizViewControllerDelelegate?
    
    private var presenter: MovieQuizPresenter!

    let alertPresenter = AlertPresenter()


    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 20
        presenter = MovieQuizPresenter(viewController: self)
        
        showLoadingIndicator()
        presenter.questionFactory?.loadData()
        
        presenter.viewController = self
        
    }
    
    // MARK: - internal
    
    
    func showAnswerResult(isCorrect: Bool) {
        presenter.didAnswer(isCorrectAnswer: isCorrect)
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        // запускаем задачу через 1 секунду c помощью диспетчера задач
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            
           // код, который мы хотим вызвать через 1 секунду
            //self.presenter.questionFactory = self.questionFactory
            self.presenter.showNextQuestionOrResults()
            self.noBorder()
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
        }
    }
    
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
 
    
    // MARK: - Private functions
    
    private func show(quiz result: QuizResultViewModel) {
        let alert = UIAlertController (
            title: result.title,
            message: result.text,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else {return}
            
            self.presenter.restartGame()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func noBorder() {
        imageView.layer.borderWidth = 0
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    
    
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let alert = UIAlertController(
            title: "Ошибка!",
            message: message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Попробовать еще раз",
                                   style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            
            self.presenter.restartGame()
        }
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }

    //MARK: - Кнопки
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        yesButton.isEnabled = false
        noButton.isEnabled = false
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        yesButton.isEnabled = false
        noButton.isEnabled = false
        presenter.noButtonClicked()
    }
}
