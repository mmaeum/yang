import SwiftUI
import SceneKit

struct StarFieldView: View {
    let scene: SCNScene
    @Binding var stars: [Star]
    let isLoading: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            // 그라데이션 배경
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 73/255, green: 43/255, blue: 0/255, opacity: 0.8)
                ]),
                center: UnitPoint(x: 0.5, y: 0.47),
                startRadius: width * 0.3,
                endRadius: width * 1.2
            )
            .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                StarListView(scene: scene, stars: $stars)
                    .frame(width: width, height: height)
            }
        }
    }
}

#Preview {
    StarFieldView(
        scene: SCNScene(),
        stars: .constant([]),
        isLoading: true,
        width: 300,
        height: 400
    )
    .background(.black)
}
