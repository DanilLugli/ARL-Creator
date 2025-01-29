
import Foundation
import SwiftUI
import SceneKit
import AlertToast

struct AutomaticRoomPositionView: View {
    
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State var selectedRoomNode: SCNNode?
    @State var selectedFloorNode: SCNNode?
    
    @State var selectedRoomNodeName: String = ""
    @State var selectedFloorNodeName: String = ""
    
    var floorView: SCNViewContainer = SCNViewContainer(empty: true)
    var roomView: SCNViewContainer = SCNViewContainer(empty: true)
    var roomsMaps: [URL]?
    
    @State var floorNodes: [String] = []
    @State var roomNodes: [SCNNode] = []
    
    @State private var showButton1 = false
    @State private var showButton2 = false
    @State private var showAddRoomPositionToast = false
    @State private var showLoadingPositionToast = false
    @State private var showAlert = false
    @State private var showSheet = false
    
    @State private var selectedMap: URL = URL(fileURLWithPath: "")
    @State private var filteredLocalMaps: [String] = []
    
    @Environment(\.dismiss) private var dismiss
    
    
    @State var responseFromServer = false {
        didSet {
            if responseFromServer {
                showSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showAlert = false
                    responseFromServer = false
                    showLoadingPositionToast = false
                }
            }
        }
    }
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["": ""])
    @State var apiResponseCode = ""
    @State var matchingNodesForAPI: [(SCNNode, SCNNode)] = []
    
    @State var originalRoomNodes: [SCNNode] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                ConnectedDotsView(
                    labels: ["1° Association", "2° Association", "3° Association", "Confirm"],
                    progress: min(matchingNodesForAPI.count + 1, 4)
                )
                
                VStack{
                    VStack {
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                            Text("Floor: \(floor.name)")
                                .bold()
                                .font(.title3)
                                .foregroundColor(Color.customBackground)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        
                    }
                    
                    ZStack {
                        floorView
                            .border(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.gray, radius: 3)
                            .padding(.horizontal, 20)
                    }.onAppear{
                        floorView.loadFloorPlanimetry(borders: false, floor: floor)
                    }
                       
                    HStack {
                        Picker(selection: $selectedFloorNodeName, label: Text("")) {
                            ForEach(sortSceneObjects(nodes: floor.sceneObjects ?? []), id: \.self) { node in
                                Text(node.name ?? "Unnamed").tag(node.name ?? "").bold()
                            }.bold()
                        }
                        .onAppear {
                            if let firstNodeName = floor.sceneObjects?.first?.name {
                                selectedFloorNodeName = firstNodeName
                            }
                        }
                        .onChange(of: selectedFloorNodeName) { oldValue, newValue in
                            floorView.resetColorNode()
                            floorView.changeColorOfNode(nodeName: newValue, color: UIColor.green)

                            selectedFloorNode = floor.sceneObjects?.first(where: { node in
                                node.name == newValue
                            })
                            if let selectedFloorNode = selectedFloorNode {
                                filterRoomNodes(byTypeOf: selectedFloorNode)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                
                Divider()
                    .frame(height: 2)
                    .background(Color.white)
                
                VStack{
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                            Text("Room: \(room.name)").bold().font(.title3).foregroundColor(Color.customBackground)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .padding(.horizontal, 20)
                        
                        
                    }
                    
                    ZStack {
                        roomView
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .shadow(color: Color.gray, radius: 3)
                    }.onAppear{
                        roomView.loadRoomPlanimetry(room: room, borders: false)
                        originalRoomNodes = room.sceneObjects ?? []
                        roomNodes = originalRoomNodes
                    }
                    
                    HStack {
                        Picker(selection: $selectedRoomNodeName, label: Text("")) {
                            ForEach(sortSceneObjects(nodes: roomNodes), id: \.self) { node in
                                Text(node.name ?? "Unnamed").tag(node.name ?? "")
                            }
                        }
                        .onAppear {
                            if let firstNodeName = roomNodes.first?.name {
                                selectedRoomNodeName = firstNodeName
                            }
                        }
                        .onChange(of: selectedRoomNodeName) { oldValue, newValue in
                            roomView.resetColorNode()
                            roomView.changeColorOfNode(nodeName: selectedRoomNodeName, color: UIColor.green)
                            selectedRoomNode = room.sceneObjects?.first(where: { node in
                                node.name == newValue
                            })
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                
                HStack {
                    Button("Confirm Relation") {
                        if let _selectedLocalNode = selectedRoomNode,
                           let _selectedGlobalNode = selectedFloorNode {
                            
                            matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))

                            selectedRoomNode = nil
                            selectedFloorNode = nil
                            selectedFloorNodeName = ""

                            roomView.resetColorNode()
                            floorView.resetColorNode()

                            resetRoomNodes()
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .frame(width: 160, height: 50)
                    .foregroundStyle(.white)
                    .background((selectedRoomNode != nil && selectedFloorNode != nil) ? Color.blue.opacity(0.4) : Color.gray.opacity(0.6))
                    .cornerRadius(30)
                    .bold()
                    
                    
                    if matchingNodesForAPI.count >= 3 {
                        Button("Calculate Position") {
                            Task {
                                showLoadingPositionToast = true

                                do {
                                    
                                    response = try await fetchAPIConversionLocalGlobal(localName: room.name, nodesList: matchingNodesForAPI)

                                    if let httpResponse = response.0 {
                                        print("Status code: \(httpResponse.statusCode)")
                                        print("Response JSON: \(response.1)")
                                    } else {
                                        print("Error: \(response.1)")
                                    }

                                    responseFromServer = true

                                   
                                    saveConversionGlobalLocal(response.1, floor.floorURL, floor)

                                
                                    floor.updateAssociationMatrixInJSON(for: room.name, fileURL: floor.floorURL.appendingPathComponent("\(floor.name).json"))

                    
                                    floor.planimetryRooms.handler.loadRoomsMaps(
                                        floor: floor,
                                        rooms: floor.rooms
                                    )

                                
                                    roomView.resetColorNode()
                                    floorView.resetColorNode()

                               
                                    showLoadingPositionToast = false
                                    showAddRoomPositionToast = true

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        dismiss()
                                    }
                                    
                                } catch {
                                    showLoadingPositionToast = false
                                }
                            }
                        }.font(.system(size: 16, weight: .bold, design: .default))
                            .frame(width: 160, height: 50)
                            .foregroundColor(.white)
                            .background(Color(red: 62/255, green: 206/255, blue: 76/255))
                            .cornerRadius(30)
                            .bold()
                    }
                }
            }
            .onDisappear{
                floorView.resetColorNode()
                roomView.resetColorNode()
            }
            .background(Color.customBackground)
            .navigationTitle("Create Room Position")
            .toast(isPresenting: $showAddRoomPositionToast) {
                AlertToast(type: .complete(Color.green), title: "Room position created successfully")
            }
            .toast(isPresenting: $showLoadingPositionToast) {
                AlertToast(type: .loading, title: "Creating Position")
            }
        }
    }
    
    
    func filterRoomNodes(byTypeOf selectedFloorNode: SCNNode) {
        let selectedType = extractType(from: selectedFloorNode.name ?? "")
        print("Tipo selezionato: \(selectedType)")
        
        roomNodes = originalRoomNodes.filter { node in
            let nodeType = extractType(from: node.name ?? "")
            return nodeType == selectedType
        }
        
        if let firstNodeName = roomNodes.first?.name {
            selectedRoomNodeName = firstNodeName
        } else {
            selectedRoomNodeName = ""
            selectedRoomNode = nil
        }
    }
    
    func resetRoomNodes() {
        roomNodes = originalRoomNodes
    }
    
//    func resetColorOfNode(nodeName: String) {
//        // Trova tutti i nodi aggiunti con il nome "__selected__"
//        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
//            n.name == "__selected__"
//        }) {
//            // Rimuove i nodi copiati dalla scena
//            for node in nodes {
//                node.removeFromParentNode()
//            }
//        }
//        
//        // Ripristina il nodo originale
//        if let originalNode = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
//            n.name == nodeName
//        }).first {
//            if let originalMaterial = originalNode.geometry?.firstMaterial {
//                originalMaterial.diffuse.contents = UIColor.white // Colore originale o predefinito
//            }
//        }
//    }
    
    func calculateVolume(of node: SCNNode) -> Float {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        let length = max.x - min.x
        let width = max.y - min.y
        let height = max.z - min.z
        return length * width * height
    }
    
    // Funzione per estrarre il tipo dal nome del nodo
    func extractType(from nodeName: String) -> String {
        // Estrae tutti i caratteri dall'inizio fino al primo numero
        let name = nodeName.lowercased()
        var type = ""
        for character in name {
            if character.isNumber {
                break
            }
            type.append(character)
        }
        return type.isEmpty ? "unknown" : type
    }
    
    func sortSceneObjects(nodes: [SCNNode]) -> [SCNNode] {
        
        let typeOrder = ["wall", "storage", "chair", "table", "window", "door"]
        
        return nodes.sorted { (node1, node2) -> Bool in
            let type1 = extractType(from: node1.name ?? "")
            let type2 = extractType(from: node2.name ?? "")
            
            let typeIndex1 = typeOrder.firstIndex(of: type1) ?? typeOrder.count
            let typeIndex2 = typeOrder.firstIndex(of: type2) ?? typeOrder.count
            
            if typeIndex1 != typeIndex2 {
                return typeIndex1 < typeIndex2
            } else {
                let size1 = calculateVolume(of: node1)
                let size2 = calculateVolume(of: node2)
                return size1 > size2
            }
        }
    }
}

struct RoomPositionView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingIndex = buildingModel.initTryData()
        let floor = firstBuildingIndex.floors.first!
        let room = floor.rooms.first!
        
        return AutomaticRoomPositionView(floor: floor, room: room)
    }
}
