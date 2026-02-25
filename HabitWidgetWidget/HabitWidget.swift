import WidgetKit
import SwiftUI

struct Habit: Codable {
    let id: UUID
    let name: String
    let icon: String
    let streak: Int
    let lastCompleted: Date?
}

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: [Habit(id: UUID(), name: "Drink Water", icon: "drop.fill", streak: 5, lastCompleted: Date())])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> ()) {
        let habits = loadHabits()
        let entry = HabitEntry(date: Date(), habits: habits)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let habits = loadHabits()
        let currentDate = Date()
        
        var entries: [HabitEntry] = []
        for hourOffset in 0..<12 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            entries.append(HabitEntry(date: entryDate, habits: habits))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadHabits() -> [Habit] {
        let defaults = UserDefaults(suiteName: "group.com.yourname.habitwidget")
        guard let data = defaults?.data(forKey: "habits"),
              let habits = try? JSONDecoder().decode([Habit].self, from: data) else {
            return []
        }
        return habits.prefix(3).map { $0 }
    }
}

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [Habit]
}

struct HabitWidgetEntryView : View {
    var entry: HabitProvider.Entry
    @Environment(\.widgetFamily) var family
    
    func isCompletedToday(_ habit: Habit) -> Bool {
        guard let lastDate = habit.lastCompleted else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.orange.gradient)
            
            if entry.habits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text("Add habits in app")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            } else {
                VStack(spacing: family == .systemSmall ? 8 : 12) {
                    Text("Today's Habits")
                        .font(family == .systemSmall ? .caption2 : .caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ForEach(entry.habits.prefix(family == .systemSmall ? 2 : 3), id: \.id) { habit in
                        HStack(spacing: 8) {
                            Image(systemName: habit.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 20)
                            
                            Text(habit.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                Text("\(habit.streak)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            
                            Image(systemName: isCompletedToday(habit) ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(isCompletedToday(habit) ? .white : .white.opacity(0.4))
                        }
                    }
                }
                .padding()
            }
        }
    }
}

@main
struct HabitWidget: Widget {
    let kind: String = "HabitWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Streak")
        .description("Track daily habits and streaks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
