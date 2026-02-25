import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var showingAddHabit = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            List {
                Section("My Habits") {
                    if viewModel.habits.isEmpty {
                        Text("No habits yet. Tap + to start tracking!")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.habits) { habit in
                            HabitRow(habit: habit, viewModel: viewModel)
                        }
                        .onDelete(perform: viewModel.deleteHabit)
                    }
                }
                
                Section {
                    Button(action: { showingPaywall = true }) {
                        HStack {
                            Image(systemName: viewModel.isPro ? "checkmark.circle.fill" : "crown.fill")
                            Text(viewModel.isPro ? "Pro Active" : "Track More Habits - $0.99")
                        }
                        .foregroundColor(viewModel.isPro ? .green : .orange)
                    }
                    .disabled(viewModel.isPro)
                }
            }
            .navigationTitle("Habit Streak")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if viewModel.canAddMore() {
                            showingAddHabit = true
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(viewModel: viewModel)
            }
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    
    var isCompletedToday: Bool {
        guard let lastDate = habit.lastCompleted else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isCompletedToday ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isCompletedToday ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(habit.streak) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.toggleHabit(habit) }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 32))
                    .foregroundColor(isCompletedToday ? .green : .gray.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddHabitView: View {
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    
    let icons = ["star.fill", "drop.fill", "figure.walk", "book.fill", "moon.fill", "sun.max.fill", "heart.fill", "bolt.fill"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Habit Name", text: $name)
                
                Section("Choose Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedIcon == icon ? .blue : .gray)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    viewModel.addHabit(name: name, icon: selectedIcon)
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

struct PaywallView: View {
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "flame.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Habit Streak Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Image(systemName: "infinite").foregroundColor(.orange); Text("Unlimited habits") }
                    HStack { Image(systemName: "chart.bar").foregroundColor(.orange); Text("Streak statistics") }
                    HStack { Image(systemName: "calendar").foregroundColor(.orange); Text("Calendar view") }
                    HStack { Image(systemName: "bell").foregroundColor(.orange); Text("Daily reminders") }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("$0.99")
                        .font(.system(size: 48, weight: .bold))
                    
                    Text("One-time purchase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    viewModel.purchasePro()
                    dismiss()
                }) {
                    Text("Purchase Pro")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Close") { dismiss() })
        }
    }
}
