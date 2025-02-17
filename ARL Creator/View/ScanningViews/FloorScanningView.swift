//import SwiftUI
//import AlertToast
//import ARKit
//import RoomPlan
//
//struct FloorScanningView: View {
//    @State var floor: Floor
//
//    @State private var messagesFromWorldMap: String = ""
//    @State private var worldMapNewFeatures: Int = 0
//    @State private var worldMapCounter: Int = 0
//    @State private var placeSquare = false
//
//    @State var isScanningFloor = false
//    @State var showScanningFloorCard = true
//
//    @State var showCreateFloorPlanimetryToast = false
//    @State var showDoneButton = false
//    @State var showContinueScanButton = false
//    @State var showCreateFloorPlanimetryButton = false
//
//    @State var captureView: FloorCaptureViewContainer?
//
//    @State private var dimensions: [String] = []
//    @State var message = ""
//    @State private var mapName: String = ""
//
//    @Environment(\.dismiss) var dismiss
//
//    init(floor: Floor) {
//        self.floor = floor
//    }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if isScanningFloor, let captureView = captureView {
//                    captureView
//                        .edgesIgnoringSafeArea(.all)
//                        .toolbarBackground(.hidden, for: .navigationBar)
//                }
//
//                else {
//
//                    VStack{
//                        Text("How to Scan a Floor")
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.gray)
//
//                        Image(systemName: "camera.viewfinder")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 70, height: 70)
//                            .foregroundColor(.gray)
//
//                        Spacer()
//                    }
//                    VStack{
//                        Text("""
//                                    • Scan **one room at a time** for better accuracy.
//                                    • When you finish scanning a room, press **Done**.
//                                    • To scan another room, press **Continue Scan**.
//                                    • When all rooms are scanned, press **Create Floor** to generate the final planimetry.
//                                    """)
//                        .multilineTextAlignment(.leading)
//                        .padding()
//                        .foregroundColor(.gray)
//                        .font(.system(size: 16))
//
//                        Text("PRESS START TO SCAN \(floor.name)")
//                            .foregroundColor(.gray)
//                            .bold()
//                    }
//
//
//                }
//
//                VStack {
////
////                    if let scene = floor.scene {
////                        SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
////                            .frame(height: 300)
////                            .background(Color.black.opacity(0.2))
////                            .cornerRadius(10)
////                            .padding()
////                            .overlay(
////                                Text("Preview of Captured Structure")
////                                    .font(.headline)
////                                    .foregroundColor(.white)
////                                    .padding(),
////                                alignment: .topLeading
////                            )
////                    }
//
//                    VStack {
//                        Spacer()
//
//                        HStack {
//
//                            if showContinueScanButton {
//                                Button(action: {
//                                    captureView?.continueCapture()
//                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
//                                    showDoneButton = true
//                                    showContinueScanButton = false
//                                    showCreateFloorPlanimetryButton = false
//                                }) {
//                                    Text("Continue Scan")
//                                        .font(.system(size: 16, weight: .bold))
//                                        .padding()
//                                        .background(Color.orange)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(30)
//                                        .frame(maxWidth: 150)
//                                }
//                            }
//
//                            Spacer()
//
//                            VStack {
//
//                                if showDoneButton {
//                                    Button(action: {
//                                        captureView?.stopCapture(pauseARSession: false)
//                                        showDoneButton = false
//                                        showContinueScanButton = true
//                                        showCreateFloorPlanimetryButton = true
//                                    }) {
//                                        Text("Done")
//                                            .font(.system(size: 16, weight: .bold))
//                                            .padding()
//                                            .background(Color.green)
//                                            .foregroundColor(.white)
//                                            .cornerRadius(30)
//                                            .frame(maxWidth: 100)
//                                    }
//
//                                }
//
//                                if showCreateFloorPlanimetryButton {
//                                    Button(action: {
//                                        captureView?.stopCapture(pauseARSession: true)
//                                        Task {
//                                            await captureView?.sessionDelegate.generateCapturedStructureAndExport(to: floor.floorURL)
//                                        }
//                                        _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
//                                        showCreateFloorPlanimetryToast = true
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                            dismiss()
//                                        }
//                                    }) {
//                                        Text("Save Floor")
//                                            .font(.system(size: 16, weight: .bold))
//                                            .padding()
//                                            .background(Color.blue)
//                                            .foregroundColor(.white)
//                                            .cornerRadius(30)
//                                            //.frame(maxWidth: 150)
//                                    }
//                                }
//                            }
//                        }
//                        .padding([.leading, .trailing, .bottom], 12)
//                    }
//
//                    Spacer()
//
//                    if !isScanningFloor {
//                        Button(action: {
//                            isScanningFloor = true
//                            captureView = FloorCaptureViewContainer(floor: floor)
//                            showDoneButton = true
//                            showContinueScanButton = false
//                            showCreateFloorPlanimetryButton = false
//                        }) {
//                            Text("Start")
//                                .font(.system(size: 18, weight: .bold, design: .default))
//                                .bold()
//                                .padding()
//                                .background(Color.green)
//                                .foregroundColor(.white)
//                                .cornerRadius(30)
//                        }
//                        .padding()
//                    }
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .worldMapCounter)) { notification in
//                    if let counter = notification.object as? Int {
//                        self.worldMapCounter = counter
//                    }
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .worldMapMessage)) { notification in
//                    if let worldMap = notification.object as? ARWorldMap {
//                        self.messagesFromWorldMap = """
//                        features: \(worldMap.rawFeaturePoints.identifiers.count)
//                        """
//                    }
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .worldMapNewFeatures)) { notification in
//                    if let newFeatures = notification.object as? Int {
//                        self.worldMapNewFeatures = newFeatures
//                    }
//                }
//                .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
//                    if let message = notification.object as? String {
//                        self.message = message
//                    }
//                }
//            }
//            .background(Color.customBackground.ignoresSafeArea())
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text(floor.name)
//                        .font(.system(size: 26, weight: .heavy))
//                        .foregroundColor(.white)
//                }
//            }
//            .toast(isPresenting: $showCreateFloorPlanimetryToast) {
//                AlertToast(type: .complete(Color.green), title: "Floor Planimetry created")
//            }
//        }
//    }
//}
//
//struct FloorScanningView_Previews: PreviewProvider {
//    static var previews: some View {
//        FloorScanningView(floor: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _floorURL: URL(fileURLWithPath: "")))
//    }
//}

import SwiftUI
import AlertToast
import ARKit
import RoomPlan
import _SceneKit_SwiftUI

struct FloorScanningView: View {
    @State var floor: Floor
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var placeSquare = false
    
    // Variabile per scegliere l'azione in alto (1: Last Room Scan, 2: Floor Planimetry)
    @State private var selectedOption: Int? = 1
    
    @State var isScanningFloor = false
    @State var showScanningFloorCard = true
    
    @State private var scanningError: String? = ""
    
    @State var showCreateFloorPlanimetryToast = false
    @State var showDoneButton = false
    @State var showContinueScanButton = false
    @State var showCreateFloorPlanimetryButton = false
    
    @State var captureView: FloorCaptureViewContainer?
    @ObservedObject var sessionDelegate: FloorCaptureViewContainer.SessionDelegate
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    // Variabile per mostrare la preview della SCNScene
    @State private var showPreview: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    init(floor: Floor) {
        self.floor = floor
        sessionDelegate = FloorCaptureViewContainer.SessionDelegate(floor: floor)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Capture view per la scansione AR o istruzioni statiche
                if isScanningFloor, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                        .toolbarBackground(.hidden, for: .navigationBar)
                } else {
                    VStack {
                        Text("How to Scan a Floor")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                        Spacer()
                    }.padding()
                    VStack {
                        Text("""
                            • Scan **one room at a time** for better accuracy.
                            • To scan another room, press **Continue**.
                            • When all rooms are scanned, press **Finish** to               generate the final planimetry.
                            """)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
//                        Text("PRESS START TO SCAN \(floor.name)")
//                            .foregroundColor(.gray)
//                            .bold()
                    }
                }
                
                // Se showContinueScanButton è attivo, mostriamo un Picker segmentato in alto,
                // abbassato con un padding extra per non sovrapporsi all'overlay Create Floor.
                if showContinueScanButton {
                    VStack {
                        Spacer().frame(height: 10) // Aggiunge uno spazio extra in alto
                        Picker("Opzioni", selection: $selectedOption) {
                            Text("Last Room Scan").tag(1)
                            Text("Floor Planimetry").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedOption) { newValue in
                            if newValue == 1 {
                                showPreview = false
                            } else if newValue == 2 {
                                showPreview = true
                            }
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: showContinueScanButton)
                }
                
                // Controlli in basso
                VStack {
                    Spacer()
                    
                    // Contenitore orizzontale (basso) che occupa tutta la larghezza
                    HStack(alignment: .bottom) {
                        // Gruppo sinistro: "Repeat" e freccia blu, allineati a sinistra
                        HStack(spacing: 8) {
                            VStack{
                                if let scanningError = scanningError, !scanningError.isEmpty{

                                        Text("An error occurred:")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                            .padding(.bottom, 5)
                                        
                                        Text(scanningError)
                                            .font(.subheadline)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 20)
                                    
                                        Button(action: {
                                            captureView?.continueCapture()
                                            self.scanningError = ""
                                        }) {
                                            Text("Restart Scan")
                                                .font(.system(size: 16, weight: .bold, design: .default))
                                                .bold()
                                                .padding()
                                                .frame(maxWidth: .infinity)
    //                                                    .background(Color.red)
                                                .foregroundColor(.red)
                                                .cornerRadius(30)
                                        }
                                        .padding(.horizontal, 20)
                                    
                                }
                            }
                            
                            
                            if showContinueScanButton {
                                Button(action: {
                                    captureView?.redoLastCapture()
                                    showPreview = false
                                    showDoneButton = true
                                    showContinueScanButton = false
                                    showCreateFloorPlanimetryButton = false
                                    selectedOption = 1
                                    print("DEBUG: Azione Repeat eseguita")
                                }) {
                                    Text("Repeat")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.red)
                                }
                                Spacer()
                                if showCreateFloorPlanimetryButton {
                                    
                                    Spacer()
                                    Button(action: {
                                        captureView?.stopCapture(pauseARSession: true)
                                        Task {
                                            await captureView?.sessionDelegate.generateCapturedStructureAndExport(to: floor.floorURL)
                                        }
                                        _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                        showCreateFloorPlanimetryToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            dismiss()
                                        }
                                        print("DEBUG: Azione Create Floor eseguita")
                                    }) {
                                        Text("Finish")
                                            .font(.system(size: 18, weight: .bold))
                                            .padding()
                                            .foregroundColor(.green)
                                    }
                                    // Utilizza un RoundedRectangle per definire l'area interattiva
                                    .contentShape(RoundedRectangle(cornerRadius: 10))
                                    .padding(.trailing, 12)
                                }
                                Spacer()
                                
                                Button(action: {
                                    showPreview = false
                                    captureView?.continueCapture()
                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                    showDoneButton = true
                                    showContinueScanButton = false
                                    showCreateFloorPlanimetryButton = false
                                    selectedOption = 1
                                }) {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        VStack(spacing: 10) {
                            if showDoneButton {
                                Button(action: {
                                    captureView?.stopCapture(pauseARSession: false)
                                    showDoneButton = false
                                    showContinueScanButton = true
                                    showCreateFloorPlanimetryButton = true
                                    selectedOption = 1
                                    if selectedOption == 2 {
                                        showPreview = true
                                    }
                                    print("DEBUG: Azione Done eseguita")
                                }) {
                                    Text("Done")
                                        .font(.system(size: 18, weight: .bold))
                                        .padding()
                                        .foregroundColor(.white)
                                        .frame(maxWidth: 100)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding([.leading, .trailing, .bottom], 12)
                    
                    // Pulsante "Start" (quando non si sta scansionando)
                    if !isScanningFloor {
                        Button(action: {
                            isScanningFloor = true
                            captureView = FloorCaptureViewContainer(floor: floor)
                            showDoneButton = true
                            showContinueScanButton = false
                            showCreateFloorPlanimetryButton = false
                        }) {
                            Text("Start")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .bold()
                                .padding()
//                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        .padding()
                    }
                }
                
                
                // Preview della SCNScene (sovrapposta) spostata più in basso
                if showPreview, let scene = floor.scene {
                    //                if true{
                    HStack {
                        SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                            .frame(maxWidth: .infinity, minHeight: 500, maxHeight: 570)
                            .cornerRadius(8)
                            .padding(.top, 10) // Aumentato il padding superiore per abbassare la preview
                            .onAppear {
                                scene.rootNode.enumerateChildNodes { node, _ in
                                    if let nodeName = node.name?.lowercased(), nodeName.contains("floor") {
                                        node.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
                                    }
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
                    .transition(.opacity)
                    .animation(.easeInOut, value: showPreview)
                }
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(floor.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(Color.white)
                }
            }
            .toast(isPresenting: $showCreateFloorPlanimetryToast) {
                AlertToast(type: .complete(Color.green), title: "Floor Planimetry created")
            }
            .onReceive(NotificationCenter.default.publisher(for: .worldMapCounter)) { notification in
                if let counter = notification.object as? Int {
                    self.worldMapCounter = counter
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .worldMapMessage)) { notification in
                if let worldMap = notification.object as? ARWorldMap {
                    self.messagesFromWorldMap = "features: \(worldMap.rawFeaturePoints.identifiers.count)"
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .worldMapNewFeatures)) { notification in
                if let newFeatures = notification.object as? Int {
                    self.worldMapNewFeatures = newFeatures
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    self.message = message
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    if message == "World tracking failure" {
                        self.scanningError = message
                    }
                    
                }
            }
        }
    }
}

struct FloorScanningView_Previews: PreviewProvider {
    static var previews: some View {
        FloorScanningView(floor: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _floorURL: URL(fileURLWithPath: "")))
    }
}
