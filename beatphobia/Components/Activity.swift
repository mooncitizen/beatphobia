//
//  Activity.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//
import SwiftUI

struct ActivityCard: View {
    let title: String
    let imageName: String
    let alignment: Alignment

    var body: some View {
        ZStack(alignment: alignment) {
            Image(imageName)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary)
                .grayscale(1.0)
            
            Text(title)
                .font(.custom(AppConstants.defaultFontName, size: 24))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
        }
        .clipped()
        .cornerRadius(20)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("My Activity")
            .font(.custom(AppConstants.defaultFontName, size: 32))
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.top)

        HStack(spacing: 16) {
            VStack(spacing: 16) {
                ActivityCard(title: "Mountains", imageName: "mountains", alignment: .topLeading)
                ActivityCard(title: "Sleep", imageName: "sleep", alignment: .bottomLeading)
            }
            
            ActivityCard(title: "Water", imageName: "water", alignment: .topLeading)
        }
        .frame(maxHeight: 400)
        .padding(.horizontal)
        
        Spacer()
    }
}
