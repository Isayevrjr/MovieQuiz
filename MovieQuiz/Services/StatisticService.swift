import UIKit

final class StatisticService: StatisticServiceProtocol {
    
    private enum Keys: String {
        case correct, total, bestGame, gamesCount, date
    }
    
    private var correctAnswers: Int = 0
    private let storage: UserDefaults = .standard
    
    var totalAccuracy: Double {
        ((Double(total) / Double(gamesCount)) * 10)
    }
    
    var correct: Int {
        get {
            storage.integer(forKey: Keys.correct.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.correct.rawValue)
        }
    }
    
    var total: Int {
        get {
            storage.integer(forKey: Keys.total.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.total.rawValue)
        }
    }
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    
    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.correct.rawValue)
            let total = storage.integer(forKey: Keys.total.rawValue)
            let date = storage.object(forKey: Keys.date.rawValue) as? Date ?? Date()
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.correct.rawValue)
            storage.set(newValue.total, forKey: Keys.total.rawValue)
            storage.set(newValue.date, forKey: Keys.date.rawValue)
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        correct = count
        total += count
        gamesCount += 1
        
        let newRecord = GameResult(correct: correct, total: amount, date: Date())
        
        if newRecord.isBetterThan(bestGame) {
            bestGame = newRecord
        }
    }
}
