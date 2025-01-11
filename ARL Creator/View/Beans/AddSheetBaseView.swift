//
//  AddSheetBaseView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 11/01/25.
//

import SwiftUI

struct AddSheetBaseView: View {
    let title: String
    let placeholder: String
    let buttonText: String
    @Binding var textInput: String
    let onAdd: () -> Void
    let isAddButtonDisabled: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack{
                Image(systemName: "plus.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.title)
                    .foregroundColor(.customBackground)
                    .bold()
                //.padding(.top)
            }
            
            TextField(placeholder, text: $textInput)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.customBackground)
                .cornerRadius(8)
                .padding(.horizontal)
            
            
            Button(action: onAdd) {
                Text(buttonText)
                    .font(.headline)
                    .bold()
                    .padding()
                    .background(isAddButtonDisabled ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
            .disabled(isAddButtonDisabled)
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        //.padding()
    }
}
