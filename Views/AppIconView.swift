import SwiftUI



struct AppIconView: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2237)
                .fill(Color.orange)

            Text("U")
                .font(.system(size: size * 0.62, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .offset(y: size * 0.03)

            Circle()
                .fill(Color(red: 1.0, green: 0.85, blue: 0.4))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.27, y: -size * 0.27)
        }
        .frame(width: size, height: size)
    }
}


struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()
            VStack(spacing: 16) {
                AppIconView(size: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                Text("UniPlan")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Plan zajęć I2S")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

#Preview("Icon") {
    AppIconView(size: 200)
        .padding(40)
}

#Preview("Launch") {
    LaunchScreenView()
}

#Preview("Icon sizes") {
    HStack(spacing: 20) {
        AppIconView(size: 29)
        AppIconView(size: 40)
        AppIconView(size: 60)
        AppIconView(size: 76)
        AppIconView(size: 120)
    }
    .padding()
}
