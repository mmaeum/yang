import SwiftUI

struct HeaderTextView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Memory Bank")
                .font(Font.custom("ShareTechMono-Regular", size: 28))
                .foregroundColor(.white)
            Text("Memories are not just about the past.\nThey shape who we are")
                .font(Font.custom("ShareTechMono-Regular", size: 14))
                .foregroundColor(.white)
                .opacity(0.6)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
    }
}

#Preview {
    HeaderTextView()
        .background(.black)
}