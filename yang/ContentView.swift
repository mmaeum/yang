import SwiftUI
import SceneKit
 
struct ContentView: View {
    private let scene: SCNScene = {
        let scene = SCNScene()
        scene.background.contents = UIColor.black

        // 300개 별 생성
        for i in 0..<300 {
            let sphere = SCNSphere(radius: 0.05)
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.white
            mat.emission.contents = UIColor.white
            mat.lightingModel = .constant
            sphere.materials = [mat]

            let node = SCNNode(geometry: sphere)
            node.name = "\(i)"
            node.position = SCNVector3(
                Float.random(in: -20...20),
                Float.random(in: -20...20),
                Float.random(in: -20...20)
            )
            scene.rootNode.addChildNode(node)
        }

        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.position = SCNVector3(0, 0, 30)
        scene.rootNode.addChildNode(camNode)

        return scene
    }()

    var body: some View {
        SceneTapView(scene: scene)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}

