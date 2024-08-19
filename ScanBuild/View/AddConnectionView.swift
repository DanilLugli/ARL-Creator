import SwiftUI
import Foundation

struct AddConnectionView: View {
    
    var selectedBuilding: Building
    var initialSelectedFloor: Floor? = nil
    var initialSelectedRoom: Room? = nil
    @State var selectedFloor: Floor?
    @State var selectedRoom: Room?
    @State private var fromFloor: Floor?
    @State private var fromRoom: Room?
    @State private var fromTransitionZone: TransitionZone?
    
    @State private var selectedTransitionZone: TransitionZone? = nil
    @State private var showAlert: Bool = false
    @State private var isElevator: Bool = false
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(selectedBuilding.name) > New Connection")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                ConnectedDotsView(labels: ["1° Connection From", "2° Connection To"], progress: fromTransitionZone == nil ? 1 : 2).padding()
                Text("Choose Floor").font(.system(size: 22))
                    .fontWeight(.heavy)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedBuilding.floors) { floor in
                            ConnectionCardView(name: floor.name, date: floor.lastUpdate, isSelected: selectedFloor?.id == floor.id  ).padding()
                                .onTapGesture {
                                    selectedFloor = floor
                                    selectedRoom = nil // Clear selected room when floor changes
                                }
                        }
                    }
                }
                
                if let selectedFloor = selectedFloor {
                    VStack {
                        Divider()
                        Text("Choose Room").font(.system(size: 22))
                            .fontWeight(.heavy)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedFloor.rooms) { room in
                                    if room.name != fromRoom?.name {
                                        ConnectionCardView(name: room.name, date: room.lastUpdate, isSelected: selectedRoom?.id == room.id  ).padding()
                                            .onTapGesture {
                                                selectedRoom = room
                                            }
                                    }
                                }
                            }
                        }
                    }.padding()
                }
                
                if let selectedRoom = selectedRoom {
                    VStack {
                        Divider()
                        Text("Choose Transition Zone").font(.system(size: 22))
                            .fontWeight(.heavy)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedRoom.transitionZones) { transitionZone in
                                    ConnectionCardView(name: transitionZone.name, date: Date(), isSelected: selectedTransitionZone?.id == transitionZone.id ).padding()
                                        .onTapGesture {
                                            selectedTransitionZone = transitionZone
                                        }
                                }
                            }
                        }
                    }.padding()
                }
                
                if selectedTransitionZone != nil {
                    Spacer()
                    Button(action: {
                        if fromTransitionZone != nil {
                            insertConnection()
                            showAlert = true
                            dismiss()
                        } else {
                            fromTransitionZone = selectedTransitionZone
                            fromFloor = selectedFloor
                            fromRoom = selectedRoom
                        }
                        
                        selectedTransitionZone = nil
                        selectedRoom = nil
                        selectedFloor = nil
                    }) {
                        VStack {
                            if (fromTransitionZone != nil) {
                                Toggle(isOn: $isElevator) {
                                    Text("Elevator Connection")
                                }
                                .toggleStyle(SwitchToggleStyle()).padding()
                            }
                            Text(fromTransitionZone == nil ? "SELECT START" : "SAVE")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.customBackground)
            .foregroundColor(.white)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Connection Created"), message: Text("Connection created successfully"))
            }
            .onAppear {
                
                DispatchQueue.main.async {
                    selectedFloor = initialSelectedFloor
                    selectedRoom = initialSelectedRoom
                }
                
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NEW CONNECTION")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }
    
    private func createConnection() -> (Connection, Connection)? {
        if (fromFloor?.name == selectedFloor?.name) {
            if let fromRoomName = fromRoom?.name, let toRoomName = selectedRoom?.name {
                let connection = SameFloorConnection(name: "Same Floor Connection", targetRoom: toRoomName)
                let mirrorConnection = SameFloorConnection(name: "Same Floor Connection", targetRoom: fromRoomName)
                
                let newTransitionZone = TransitionZone(name: "New Transition Zone", connection: mirrorConnection, transitionArea: Coordinates(x: 1, y: 2))
                
                // Aggiungi la nuova TransitionZone all'array transitionZones della stanza
                do {
                    try initialSelectedRoom?.addTransitionZone(transitionZone: newTransitionZone)
                } catch {
                    print("Errore durante l'aggiunta della TransitionZone: \(error)")
                }
                return (connection, mirrorConnection)
            }
        }
        
        if !isElevator {
            if let fromFloorName = fromFloor?.name, let fromRoomName = fromRoom?.name, let toFloorName = selectedFloor?.name, let toRoomName = selectedRoom?.name {
                let connection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: toFloorName, targetRoom: toRoomName)
                let mirrorConnection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: fromFloorName, targetRoom: fromRoomName)
                
                let newTransitionZone = TransitionZone(name: "New Transition Zone", connection: mirrorConnection, transitionArea: Coordinates(x: 1, y: 2))
                
                // Aggiungi la nuova TransitionZone all'array transitionZones della stanza
                do {
                    try initialSelectedRoom?.addTransitionZone(transitionZone: newTransitionZone)
                } catch {
                    print("Errore durante l'aggiunta della TransitionZone: \(error)")
                }
                
                return (connection, mirrorConnection)
            }
        }
        
        if let fromFloorName = fromFloor?.name, let fromRoomName = fromRoom?.name, let toFloorName = selectedFloor?.name, let toRoomName = selectedRoom?.name {
            let connection = ElevatorConnection(name: "Elevator Connection", targetFloor: toFloorName, targetRoom: toRoomName)
            let mirrorConnection = ElevatorConnection(name: "Elevator Connection", targetFloor: fromFloorName, targetRoom: fromRoomName)
            return (connection, mirrorConnection)
        }
        return nil
    }
    
    func insertConnection() {
        if let (fromConnection, toConnection) = createConnection() {
            fromTransitionZone?.connection = fromConnection
            selectedTransitionZone?.connection = toConnection
        }
    }
}

struct AddConnection_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let selectedBuilding = buildingModel.initTryData()
        let floor = selectedBuilding.floors.first!
        let room = floor.rooms.first!
        
        return AddConnectionView(selectedBuilding: selectedBuilding, initialSelectedFloor: floor, initialSelectedRoom: room)
    }
}
