import SwiftUI
import AlertToast
import Foundation

struct BuildingsView: View {
    
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText = ""
    @State private var selectedBuilding: Building? = nil
    @State private var navigationPath = NavigationPath()
    
    @State private var isAddBuildingSheetPresented = false
    @State private var newBuildingName = ""
    
    @State private var showAddBuildingToast = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if buildingsModel.getBuildings().isEmpty {
                    VStack {
                        HStack(spacing: 4) {
                            Text("Add building with")
                                .foregroundColor(.gray)
                                .font(.headline)

                            Image(systemName: "plus.circle")
                                .foregroundColor(.gray)

                            Text("icon")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                        .padding()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground.ignoresSafeArea())
                }
                else {
                    VStack {
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal, 13)
                            .frame(maxWidth: .infinity)
                        
                        ScrollView {
                            LazyVStack(spacing: 50) {
                                ForEach(filteredBuildings, id: \.id) { building in
                                    NavigationLink(destination: BuildingView(building: building)) {
                                        DefaultCardView(name: building.name, date: Date())
                                            .padding()
                                    }
                                }
                            }
                        }
                        .padding(.top, 15)
                    }.toast(isPresenting: $showAddBuildingToast) {
                        AlertToast(type: .complete(Color.green), title: "Building added!")
                    }
                }
            }
            .foregroundColor(.white)
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Buildings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddBuildingSheetPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
            }
            .sheet(isPresented: $isAddBuildingSheetPresented) {
                addBuildingSheet
            }
        }
    }
    
    var filteredBuildings: [Building] {
        if searchText.isEmpty {
            return buildingsModel.getBuildings()
        } else {
            return buildingsModel.getBuildings().filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private var addBuildingSheet: some View {
        AddSheetBaseView(
            title: "Create New Building",
            placeholder: "Building Name",
            buttonText: "Create Building",
            textInput: $newBuildingName,
            onAdd: {
                addNewBuilding()
                isAddBuildingSheetPresented = false
                showAddBuildingToast = true
            },
            isAddButtonDisabled: newBuildingName.isEmpty
        )
    }
    
    private func addNewBuilding() {
        guard !newBuildingName.isEmpty else { return }
        
        let newBuilding = Building(name: newBuildingName, lastUpdate: Date(), floors: [], buildingURL: URL(fileURLWithPath: "") )
        buildingsModel.addBuilding(building: newBuilding)
        newBuildingName = ""
        isAddBuildingSheetPresented = false
    }
}

struct BuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        
        return BuildingsView().environmentObject(buildingModel)
    }
}
