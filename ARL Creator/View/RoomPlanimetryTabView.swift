//
//  RoomPlanimetryView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import SwiftUI
import ARKit

struct RoomPlanimetryTabView: View {
    @ObservedObject var room: Room

    var body: some View {
        VStack {
            if room.planimetry.scnView.scene == nil {
                HStack(spacing: 4) {
                    Text("Add Planimetry for \(room.name) with")
                        .foregroundColor(.gray)
                        .font(.headline)

                    Image(systemName: "plus.circle")
                        .foregroundColor(.gray)

                    Text("icon")
                        .foregroundColor(.gray)
                        .font(.headline)
                }
                .padding()
            } else {
                VStack {
                    ZStack {
                        room.planimetry
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}
