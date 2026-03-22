import SwiftUI


struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: ScheduleStore
    @State private var page = 0
    @State private var notificationsGranted = false
    @State private var minutesBefore = 10

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "calendar.badge.clock",
            color: .orange,
            title: "Twój plan zajęć",
            subtitle: "Plan I2S gr. 2/3 na semestr letni 2025/2026 jest już wczytany. Możesz przeglądać zajęcia, edytować je i dodawać zadania."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            color: Color(red: 0.3, green: 0.6, blue: 0.9),
            title: "Przypomnienia",
            subtitle: "Ustawię powiadomienia przed każdymi zajęciami, żebyś nigdy o nich nie zapomniała."
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            color: Color(red: 0.25, green: 0.72, blue: 0.45),
            title: "Zadania i egzaminy",
            subtitle: "Dodawaj zadania bezpośrednio z karty zajęć. Przesuń w lewo żeby usunąć, zaznacz żeby ukończyć."
        ),
    ]

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.orange : Color.secondary.opacity(0.3))
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: page)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 48)

                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        PageContent(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 360)

               
                if page == 1 {
                    notificationsSetup
                        .padding(.horizontal, 32)
                        .padding(.top, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                Button(action: nextPage) {
                    Text(page == pages.count - 1 ? "Zaczynamy!" : "Dalej")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                if page < pages.count - 1 {
                    Button("Pomiń") {
                        isPresented = false
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
                } else {
                    Spacer().frame(height: 32)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: page)
    }


    private var notificationsSetup: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Powiadamiaj mnie")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Stepper("\(minutesBefore) min przed", value: $minutesBefore, in: 5...30, step: 5)
                    .labelsHidden()
                Text("\(minutesBefore) min przed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if notificationsGranted {
                Label("Powiadomienia włączone", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.25, green: 0.72, blue: 0.45))
            } else {
                Button {
                    Task {
                        notificationsGranted = await NotificationManager.shared.requestPermission()
                    }
                } label: {
                    Label("Włącz powiadomienia", systemImage: "bell.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.3, green: 0.6, blue: 0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }


    private func nextPage() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            if notificationsGranted {
                Task {
                    await NotificationManager.shared.scheduleAll(
                        classes: store.classes,
                        minutesBefore: minutesBefore
                    )
                }
            }
            isPresented = false
        }
    }
}


struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

struct PageContent: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 32)
        }
    }
}
