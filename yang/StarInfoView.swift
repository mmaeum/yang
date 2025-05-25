import SwiftUI

struct StarInfoView: View {
    let index: Int
    @Environment(\\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                    Text("뒤로가기")
                }
                .padding()
                Spacer()
            }
            Spacer()
            Text("Star Index: \(index)")
                .font(.title)
            Text("Hello World")
                .font(.headline)
            Button("Button") {
                // 아무 기능 없음
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .edgesIgnoringSafeArea(.all)
    }
}
