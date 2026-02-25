import SwiftUI
import WidgetKit

struct Habit: Identifiable, Codable {
    let id = UUID()
    var name: String
    var icon: String
    var streak: Int
    var lastCompleted: Date?
}

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var isPro = false
    
    private let defaults = UserDefaults(suiteName: "group.com.yourname.habitwidget")
    private let habitsKey = "habits"
    private let proKey = "isProUser"
    private let freeLimit = 3
    
    init() {
        loadHabits()
        isPro = defaults?.bool(forKey: proKey) ?? false
    }
    
    func canAddMore() -> Bool {
        return isPro || habits.count < freeLimit
    }
    
    func addHabit(name: String, icon: String) {
        let habit = Habit(name: name, icon: icon, streak: 0, lastCompleted: nil)
        habits.append(habit)
        saveHabits()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func deleteHabit(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        saveHabits()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func toggleHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let calendar = Calendar.current
            
            if let lastDate = habits[index].lastCompleted,
               calendar.isDateInToday(lastDate) {
                // Uncomplete
                habits[index].lastCompleted = nil
                habits[index].streak = max(0, habits[index].streak - 1)
            } else {
                // Complete
                habits[index].lastCompleted = Date()
                
                // Check if yesterday was completed
                if let lastDate = habit.lastCompleted,
                   calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: Date())!) {
                    habits[index].streak += 1
                } else {
                    habits[index].streak = 1
                }
            }
            
            saveHabits()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            defaults?.set(encoded, forKey: habitsKey)
        }
    }
    
    private func loadHabits() {
        if let data = defaults?.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
    
    func purchasePro() {
        isPro = true
        defaults?.set(true, forKey: proKey)
    }
}
