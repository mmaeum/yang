import SwiftUI

struct CountdownTimerView: View {
    let timeLeft: String
    
    var body: some View {
        VStack {
            Text(timeLeft)
                .font(Font.custom("PressStart2P-Regular", size: 16))
                .foregroundColor(.white)
            Text("left for the next memory")
                .font(Font.custom("ShareTechMono-Regular", size: 12))
                .foregroundColor(.white)
                .opacity(0.6)
                .padding(.top, 10)
        }
    }
}

#Preview {
    CountdownTimerView(timeLeft: "12:34:56")
        .background(.black)
}