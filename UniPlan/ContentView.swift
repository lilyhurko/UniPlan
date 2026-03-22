import SwiftUI

struct ContentView: View {
    @StateObject private var store     = ScheduleStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var examStore = ExamStore()
    @State private var selectedTab: Tab = .today
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    enum Tab { case today, schedule, search, tasks, more }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Dziś", systemImage: "sun.max.fill") }
                .tag(Tab.today)

            ScheduleView()
                .tabItem { Label("Plan", systemImage: "calendar") }
                .tag(Tab.schedule)

            SearchView()
                .tabItem { Label("Szukaj", systemImage: "magnifyingglass") }
                .tag(Tab.search)

            TasksView()
                .tabItem { Label("Zadania", systemImage: "checkmark.circle.fill") }
                .tag(Tab.tasks)

            MoreView(importedClasses: .constant([]))
                .tabItem { Label("Więcej", systemImage: "ellipsis.circle.fill") }
                .tag(Tab.more)
        }
        .tint(.orange)
        .environmentObject(store)
        .environmentObject(taskStore)
        .environmentObject(examStore)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .environmentObject(store)
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
                hasSeenOnboarding = true
            }
        }
      
        .onChange(of: taskStore.tasks) { _, _ in
            taskStore.savePublic()
        }
    }
}

#Preview {
    ContentView()
}
