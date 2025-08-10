import SwiftUI

struct HamburgerMenuButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.40))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.30), lineWidth: 0.25)
                    )
                VStack(spacing: 3) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 2)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 2)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 2)
                }
            }
        }
    }
}

#Preview {
    HamburgerMenuButton {
        print("Menu tapped")
    }
    .background(.black)
}