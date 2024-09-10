//
//  AddTransitionZoneView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 07/09/24.
//

import SwiftUI

struct AddTransitionZoneView: View {
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State private var transitionZoneName: String = ""
    
    @State private var showUpdateAlert = false
    
//  @StateObject var mapTransitionView = SCNViewTransitionZoneContainer()
    @StateObject var viewModel = SCNViewModel()  // Cambiato a ViewModel
    
    var body: some View{
        VStack{
            Text("Insert the name of the Transition Zone")
                .font(.title3)
                .padding(.top)
            
            TextField("Transition Zone Name", text: $transitionZoneName)
                .frame(width: 350, height: 50)
                .foregroundColor(.black)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing, .bottom])
            
            ZStack{
                SCNViewTransitionZoneContainer(viewModel: viewModel)  // Passa il ViewModel
                    .border(Color.white)
                    .cornerRadius(10)
                    .padding()
                    .shadow(color: Color.gray, radius: 3)
                VStack{
                    HStack {
                        Button("Ruota Orario") {
                            viewModel.rotateBoxClockwise()
                        }.font(.system(size: 6))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        
                        Button("Ruota Anti-orario") {
                            viewModel.rotateBoxCounterClockwise()
                        }
                        .font(.system(size: 6))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    VStack {
                        Button("Allunga in Larghezza") {
                            viewModel.stretchBoxWidth()
                        }
                        .font(.system(size: 6))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    HStack {
                        Button("Muovi Sinistra") {
                            viewModel.moveBoxLeft()
                        }
                        .font(.system(size: 6))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Muovi Destra") {
                            viewModel.moveBoxRight()
                        }
                        .font(.system(size: 6))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    HStack {
                        Button("Muovi Su") {
                            viewModel.moveBoxUp()
                        }
                        .font(.system(size: 6))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Muovi Giù") {
                            viewModel.moveBoxDown()
                        }
                        .font(.system(size: 6))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                
                
            }.onAppear {
                viewModel.loadRoomMaps(room: room, borders: true, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
            }
            HStack{
                Button(action: {
                    viewModel.removeLastBox()
                }) {
                    Text("Cancel")
                        .bold()
                        .foregroundColor(.white)
                }
                .font(.system(size: 20))
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button(action: {
                    
                    guard !transitionZoneName.isEmpty else {
                        showUpdateAlert = true
                        return
                    }
                    
                    addTransitionZoneToScene()
                    showUpdateAlert = true
                    
                }) {
                    Text("Save")
                        .bold()
                        .foregroundColor(.white)
                }
                .font(.system(size: 20))
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
           
            
        }
        .background(Color.customBackground)
        .foregroundColor(.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ADD TRANSITION ZOOM")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .alert(isPresented: $showUpdateAlert) {
            Alert(
                title: Text("ATTENTION").foregroundColor(.red),
                message: Text("Are you sure to add and save this Transition Zone?"),
                dismissButton: .default(Text("Yes")){
                    floor.objectWillChange.send()
                }
            )
        }
    }

    private func addTransitionZoneToScene() {
        
        let transitionZone = TransitionZone(name: transitionZoneName, connection: Connection(name: ""))
        room.addTransitionZone(transitionZone: transitionZone)
        print("Transition Zone \(transitionZoneName) added to the room and scene.")
    }
}

struct AddTransitionZoneView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        
        return AddTransitionZoneView(floor: floor, room: room)
    }
}



