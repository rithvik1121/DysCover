import SwiftUI

struct EnterUsernameView: View {
    @State private var localUsername: String = ""
    @State private var navigateToTestView: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Warm gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Welcome to DysCover")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#F57F17"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)

                    TextField("Enter your username", text: $localUsername)
                        .padding()
                        .background(Color(hex: "#FFFDE7").opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    Button("Continue") {
                        if !localUsername.isEmpty {
                            globalUsername = localUsername   // ✅ Update globalUsername
                            navigateToTestView = true        // ✅ Navigate to TestView
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#FBC02D"))

                    // Navigate to TestView after entering username
                    NavigationLink(destination: TestView(), isActive: $navigateToTestView) {
                        EmptyView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct EnterUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        EnterUsernameView()
    }
}
