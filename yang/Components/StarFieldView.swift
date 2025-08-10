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