import SwiftUI
import SceneKit

class SCNViewUpdatePositionRoomHandler: ObservableObject, MoveObject {
    
    private let identityMatrix = matrix_identity_float4x4

    @Published var rotoTraslation: RotoTraslationMatrix = RotoTraslationMatrix(
        name: "",
        translation: matrix_identity_float4x4,
        r_Y: matrix_identity_float4x4
    )
    
    @Published var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    @Published var floor: Floor?
    var roomName: String?
    
    var zoomStep: CGFloat = 0.1
    var translationStep: CGFloat = 0.1
    var rotationStep: Float = .pi / 100
    
    private let color: UIColor = UIColor.green.withAlphaComponent(0.3)
    
    var roomNode: SCNNode?
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
    }
    
    @MainActor
    func loadRoomMapsPosition(floor: Floor, room: Room, borders: Bool) {
        do {
            self.floor = floor
            
            self.roomName = room.name
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz")
                .appendingPathComponent("\(floor.name).usdz")
            scnView.scene = floor.scene
            
            
            self.rotoTraslation = floor.associationMatrix[room.name] ?? RotoTraslationMatrix(
                name: "",
                translation: floor.associationMatrix[room.name]?.translation ?? matrix_identity_float4x4,
                
                r_Y: floor.associationMatrix[room.name]?.r_Y ?? matrix_identity_float4x4
            )
            
            let roomScene = room.scene
            
            func createSceneNode(from scene: SCNScene) -> SCNNode {
                // Crea un nodo contenitore
                let containerNode = SCNNode()
                containerNode.name = "SceneContainer"
                
                // Cerca il nodo `Floor0`
                if let floorNode = scene.rootNode.childNode(withName: "Floor0", recursively: true) {
                    floorNode.name = "Floor0"
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.green.withAlphaComponent(0.6)
                    floorNode.geometry?.materials = [material]
                    containerNode.addChildNode(floorNode)
                } else {
                    print("Node 'Floor0' not found in the provided scene.")
                }
                
                let sphereNode = SCNNode()
                sphereNode.name = "SceneCenterMarker"
                sphereNode.position = SCNVector3(0, 0, 0)
                
                let sphereGeometry = SCNSphere(radius: 0.1) // Raggio piccolo per rappresentare il punto
                let sphereMaterial = SCNMaterial()
                sphereMaterial.emission.contents = UIColor.orange // Colore fluorescente
                sphereMaterial.diffuse.contents = UIColor.orange
                sphereGeometry.materials = [sphereMaterial]
                sphereNode.geometry = sphereGeometry
                containerNode.addChildNode(sphereNode)
                
                if let markerNode = containerNode.childNode(withName: "SceneCenterMarker", recursively: true) {
                    let localMarkerPosition = markerNode.position // Posizione locale del puntino
                    containerNode.pivot = SCNMatrix4MakeTranslation(localMarkerPosition.x, localMarkerPosition.y, localMarkerPosition.z)
                    print("Pivot impostato su SceneCenterMarker")
                } else {
                    print("SceneCenterMarker non trovato, pivot non modificato.")
                }
                
                return containerNode
            }
            
            var roomNode = createSceneNode(from: roomScene!)
            roomNode.name = room.name
            
            roomNode.simdWorldPosition = simd_float3(0,0,0)
            
            if let rotoTraslationMatrix = floor.associationMatrix[room.name] {
                applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
            } else {
                print("No RotoTraslationMatrix found for room: \(room.name)")
            }
            
            scnView.scene?.rootNode.addChildNode(roomNode)
            self.roomNode = roomNode
        } catch {
            print("Error loading scene from URL: \(error)")
        }
        
        drawSceneObjects(borders: true)
        setMassCenter()
        setCamera()
        
    }
    
    func rotateClockwise() {
        self.rotateLeft()
    }

    func rotateCounterClockwise() {
        
        self.rotateRight()
    }

    func moveUp() {
        self.moveRoomPositionDown()
    }

    func moveDown() {
        self.moveRoomPositionUp()
        
    }

    func moveLeft() {
        self.moveRoomPositionLeft()
    }

    func moveRight() {
        self.moveRoomPositionRight()
    }

    func moveRoomPositionUp() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.worldPosition.z += Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][2] += Float(translationStep)
    }

    func moveRoomPositionDown() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        
        roomNode.worldPosition.z -= Float(translationStep)
        
        floor?.associationMatrix[roomName!]?.translation[3][2] -= Float(translationStep)
    }

    func moveRoomPositionRight() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.worldPosition.x += Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][0] += Float(translationStep)
        print(floor?.associationMatrix[roomName!]?.translation[3][0] ?? 0)
    }

    func moveRoomPositionLeft() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.worldPosition.x -= Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][0] -= Float(translationStep)
    }

    func rotateRight() {
        guard let roomNode = roomNode else {
            print("No room node available for rotation")
            return
        }
        roomNode.eulerAngles.y -= rotationStep

        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(-rotationStep, 0, 1, 0))
        floor?.associationMatrix[roomName ?? ""]?.r_Y = matrix_multiply(floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4, rotationMatrix)
    }

    func rotateLeft() {
        guard let roomNode = roomNode else {
            print("No room node available for rotation")
            return
        }
        roomNode.eulerAngles.y += rotationStep
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(rotationStep, 0, 1, 0))
        floor?.associationMatrix[roomName ?? ""]?.r_Y = matrix_multiply(floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4, rotationMatrix)
        print("rotateCounterClockwise: \(String(describing: floor?.associationMatrix[roomName ?? ""]?.r_Y) )")
    }
    
    func setCamera() {
            scnView.scene?.rootNode.addChildNode(cameraNode)
            cameraNode.camera = SCNCamera()
            cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
            cameraNode.camera?.usesOrthographicProjection = true
            cameraNode.camera?.orthographicScale = 10
            cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
            
            let directionalLight = SCNNode()
            directionalLight.light = SCNLight()
            directionalLight.light!.type = .ambient
            directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
            cameraNode.addChildNode(directionalLight)
            
            scnView.pointOfView = cameraNode
            cameraNode.constraints = []
        }

    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = cameraNode.camera else { return }
        if gesture.state == .changed {
            let newScale = camera.orthographicScale / Double(gesture.scale)
            camera.orthographicScale = max(5.0, min(newScale, 50.0)) // Limita lo zoom tra 5x e 50x
            gesture.scale = 1
        }
    }
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scnView)
        cameraNode.position.x -= Float(translation.x) * 0.01 // Spostamento orizzontale
        cameraNode.position.z += Float(translation.y) * 0.01 // Spostamento verticale
        gesture.setTranslation(.zero, in: scnView)
    }
    
    private func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: {
            n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
        }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    private func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes {
            if n.worldPosition.x < X[0] { X[0] = n.worldPosition.x }
            if n.worldPosition.x > X[1] { X[1] = n.worldPosition.x }
            if n.worldPosition.z < Z[0] { Z[0] = n.worldPosition.z }
            if n.worldPosition.z > Z[1] { Z[1] = n.worldPosition.z }
        }
        massCenter.worldPosition = SCNVector3((X[0] + X[1]) / 2, 0, (Z[0] + Z[1]) / 2)
        return massCenter
    }
    
    func drawSceneObjects(borders: Bool) {
        
        var drawnNodes = Set<String>()
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: { n, _ in
                n.name != nil &&
                n.name! != "Room" &&
                n.name! != "Floor0" &&
                n.name! != "Geom" &&
                String(n.name!.suffix(4)) != "_grp" &&
                n.name! != "__selected__"
            })
            .forEach {
                let nodeName = $0.name
                let material = SCNMaterial()
                if nodeName == "Floor0" {
                    material.diffuse.contents = UIColor.green
                } else {
                    material.diffuse.contents = UIColor.black
                    if nodeName?.prefix(5) == "Floor" {
                        material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
                    }
                    if nodeName!.prefix(6) == "Transi" {
                        material.diffuse.contents = UIColor.white
                    }
                    if nodeName!.prefix(4) == "Door" {
                        material.diffuse.contents = UIColor.white
                    }
                    if nodeName!.prefix(4) == "Open"{
                        material.diffuse.contents = UIColor.systemGray5
                    }
                    if nodeName!.prefix(4) == "Tabl" {
                        material.diffuse.contents = UIColor.brown
                    }
                    if nodeName!.prefix(4) == "Chai"{
                        material.diffuse.contents = UIColor.brown.withAlphaComponent(0.4)
                    }
                    if nodeName!.prefix(4) == "Stor"{
                        material.diffuse.contents = UIColor.systemGray
                    }
                    if nodeName!.prefix(4) == "Sofa"{
                        material.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 0.6)
                    }
                    if nodeName!.prefix(4) == "Tele"{
                        material.diffuse.contents = UIColor.orange
                    }
                    material.lightingModel = .physicallyBased
                    $0.geometry?.materials = [material]
                    
                    if borders {
                        $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                        $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                        $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                    }
                }
                drawnNodes.insert(nodeName!)
            }
    }
    
    private func drawContent(borders: Bool) {
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach{
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.black
                if ($0.name!.prefix(5) == "Floor") { material.diffuse.contents = UIColor.white.withAlphaComponent(0.2) }
                if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") { material.diffuse.contents = UIColor.white }
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                
            }
    }
    
    @MainActor
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        
        let translationVector = simd_float3(
            rotoTraslation.translation.columns.3.x,
            rotoTraslation.translation.columns.3.y,
            rotoTraslation.translation.columns.3.z
        )
        node.simdPosition = node.simdPosition + translationVector
        
        let rotationMatrix = rotoTraslation.r_Y
        
        let rotationQuaternion = simd_quatf(rotationMatrix)
        
        node.simdOrientation = rotationQuaternion * node.simdOrientation
        
    }
}

struct SCNViewUpdatePositionRoomContainer: UIViewRepresentable {
    typealias UIViewType = SCNView
    var handler: SCNViewUpdatePositionRoomHandler
    
    init() {
        let scnView = SCNView(frame: .zero)
        let cameraNode = SCNNode()
        let massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.handler = SCNViewUpdatePositionRoomHandler(scnView: scnView, cameraNode: cameraNode, massCenter: massCenter)
    }
    
    func makeUIView(context: Context) -> SCNView {
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        handler.scnView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        handler.scnView.addGestureRecognizer(panGesture)
        
        return handler.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SCNViewUpdatePositionRoomContainer
        
        init(_ parent: SCNViewUpdatePositionRoomContainer) {
            self.parent = parent
        }
        
        // Gestore del pinch (zoom)
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            parent.handler.handlePinch(gesture)
        }

        // Gestore del pan (spostamento)
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            parent.handler.handlePan(gesture)
        }
    }
}

@available(iOS 17.0, *)
struct SCNViewUpdatePositionRoomContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewUpdatePositionRoomContainer()
    }
}
