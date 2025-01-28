import SwiftUI
import AlertToast
import ARKit
import RoomPlan

struct FloorScanningView: View {
    @State var floor: Floor
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var placeSquare = false
    
    @State var isScanningFloor = false
    @State var showScanningFloorCard = true
    
    @State var showCreateFloorPlanimetryToast = false
    @State var showDoneButton = false
    @State var showContinueScanButton = false
    @State var showCreateFloorPlanimetryButton = false
    
    @State var captureView: FloorCaptureViewContainer?
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    @Environment(\.dismiss) var dismiss

    init(floor: Floor) {
        self.floor = floor
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isScanningFloor, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                        .toolbarBackground(.hidden, for: .navigationBar) 
                }
                
                else {
                    Text("Press Start to begin scanning of \(floor.name)")
                        .foregroundColor(.gray)
                        .bold()
                }
                
                VStack {
                    VStack {
                        Spacer()

                        HStack {
                            if showContinueScanButton {
                                Button(action: {
                                    captureView?.continueCapture()
                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                    showDoneButton = true
                                    showContinueScanButton = false
                                    showCreateFloorPlanimetryButton = false
                                }) {
                                    Text("Continue Scan")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding()
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(30)
                                        .frame(maxWidth: 150)
                                }
                            }

                            Spacer()

                            VStack {
                                
                                if showDoneButton {
                                    Button(action: {
                                        captureView?.stopCapture(pauseARSession: false)
                                        showDoneButton = false
                                        showContinueScanButton = true
                                        showCreateFloorPlanimetryButton = true
                                    }) {
                                        Text("Done")
                                            .font(.system(size: 16, weight: .bold))
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                            .frame(maxWidth: 100)
                                    }
                                    
                                }

                                if showCreateFloorPlanimetryButton {
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
                                    }) {
                                        Text("Save Floor")
                                            .font(.system(size: 16, weight: .bold))
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                            //.frame(maxWidth: 150)
                                    }
                                }
                            }
                        }
                        .padding([.leading, .trailing, .bottom], 12)
                    }
                    
                    Spacer()
                    
                    if !isScanningFloor {
                        Button(action: {
                            isScanningFloor = true
                            captureView = FloorCaptureViewContainer(floor: floor)
                            showDoneButton = true
                            showContinueScanButton = false
                            showCreateFloorPlanimetryButton = false
                        }) {
                            Text("Start")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .bold()
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        .padding()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapCounter)) { notification in
                    if let counter = notification.object as? Int {
                        self.worldMapCounter = counter
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapMessage)) { notification in
                    if let worldMap = notification.object as? ARWorldMap {
                        self.messagesFromWorldMap = """
                        features: \(worldMap.rawFeaturePoints.identifiers.count)
                        """
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
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(floor.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .toast(isPresenting: $showCreateFloorPlanimetryToast) {
                AlertToast(type: .complete(Color.green), title: "Floor Planimetry created")
            }
        }
    }
}

struct FloorScanningView_Previews: PreviewProvider {
    static var previews: some View {
        FloorScanningView(floor: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _floorURL: URL(fileURLWithPath: "")))
    }
}
