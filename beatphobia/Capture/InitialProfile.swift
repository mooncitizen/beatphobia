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
                Text("Thanks for joining \(AppConstants.appName).")
                    .font(.system(size:33).bold())
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    .padding(.leading, 10)
                    .multilineTextAlignment(.center)
                
            }
            
            HStack(spacing: 10) {
                Text("Your journey to better mental health starts now.")
                    .font(.system(size:18))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                    .multilineTextAlignment(.center)
       
            }.padding(.top, 20)
            
            Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Almost in")
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .fontWeight(.bold)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    Text("We just need a few more details from you to get started. No one will see your name.")
                        .font(.system(size: 12))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    
                    TextField("eg: John Smith", text: $name)
                        .font(.system(size: 14))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppConstants.cardBackgroundColor(for: colorScheme))
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
                        return
                    }
                    
                    do {
                        print("SAVING TO AUTH MANAGER")
                        try await self.authManager.setProfileName(name: name)
                        
                        // Reload profile to trigger ContentView to show HomeView
                        _ = try? await self.authManager.getProfile()
                    } catch {
                        print("Error setting profile name: \(error)")
                        self.alertItem = AlertItem(title: "Error", message: "Failed to save profile. Please try again.")
                    }
                }
            }
                .buttonStyle(PillButtonStyle(style: .success)).padding(.leading, 10)
                .disabled(isSaving)
                .alert(item: $alertItem) { item in
                    Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
                }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(AppConstants.backgroundColor(for: colorScheme))
    }
}

#Preview {
    InitialProfileView()
}
