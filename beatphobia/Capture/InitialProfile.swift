//
//  InitialProfile.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


struct InitialProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name: String = ""
    @State private var isSaving: Bool = false
    
    @State private var alertItem: AlertItem?
    
    var body: some View {
        VStack {
            
            HStack{
                Text("Thanks for joining \(AppConstants.appName).").font(.system(size:33).bold()).fontDesign(.serif).padding(.leading, 10).multilineTextAlignment(.center)
                
            }
            
            HStack(spacing: 10) {
                Text("Your journey to better mental health starts now.").font(.system(size:18)).fontDesign(.serif).padding(.leading, 10).padding(.trailing, 10).multilineTextAlignment(.center)
       
            }.padding(.top, 20)
            
            Card(backgroundColor: Color(.white).opacity(1)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Almost in")
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .fontWeight(.bold)
                    Text("We just need a few more details from you to get started.")
                        .font(.system(size: 12)).fontDesign(.serif)
                    
                    
                    TextField("eg: John Smith", text: $name)
                        .font(.system(size: 14))
                        .fontDesign(.serif)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                    
                   
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(16.0)
            
            Button("Save") {
                Task {
                    self.isSaving = true
                    defer { self.isSaving = false }
                    
                    if name.isEmpty {
                        self.alertItem = AlertItem(title: "Missing Name", message: "Please enter a name to continue.")
                    }
                    
                    do {
                        print("SAVING TO AUTH MANAGER")
                        try await self.authManager.setProfileName(name: name)
                    } catch {
                        print("Error setting profile name: \(error)")
                    }
                }
            }
                .buttonStyle(PillButtonStyle(style: .success)).padding(.leading, 10)
                .disabled(isSaving)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(AppConstants.backgroundColor(for: colorScheme))
    }
}

#Preview {
    InitialProfileView()
}
