//
//  JourneyOnboardingView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 20/10/2025.
//
import Foundation
import Combine
import SwiftUI
import RealmSwift

enum JourneyOnboardingStep: Int, CaseIterable {
    case welcome
    case pathing
    case dataPrivacy
    case finish
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: JourneyOnboardingStep = .welcome
    var chosenJourneyType: JourneyType = .None
    
    func advance() {
        let allSteps = JourneyOnboardingStep.allCases
        
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return }
        
        let nextIndex = allSteps.index(after: currentIndex)
        
        if nextIndex < allSteps.endIndex {
            self.currentStep = allSteps[nextIndex]
        }
    }
    
    func previous() {
        let allSteps = JourneyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return }
        
        let nextIndex = allSteps.index(before: currentIndex)
        
        if nextIndex < allSteps.endIndex {
            self.currentStep = allSteps[nextIndex]
        }
    }
    
    func goToFirstStep() {
        self.currentStep = .welcome
    }
}


struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            switch viewModel.currentStep {
                case .welcome:
                    OnboardingWelcomeView(viewModel: viewModel)
                case .pathing:
                    OnboardingPathingView(viewModel: viewModel)
                case .dataPrivacy:
                    OnboardingDataPrivacyView(viewModel: viewModel)
                case .finish:
                    OnboardingFinishView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppConstants.backgroundColor(for: colorScheme))
        
    }
}


struct OnboardingWelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack {
            Text("Welcome to \(AppConstants.appName)").font(.largeTitle)
                .fontDesign(.serif).foregroundColor(.black)
            Text("Lets get started on your road to recovery").fontDesign(.serif).foregroundColor(.black)
            
            Button("Get Started") {
                viewModel.advance()
            }
            .buttonStyle(PillButtonStyle(style: .neutral)).padding(.top, 80)
        }
    }
}

struct OnboardingPathingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    private let journeyTypes: [JourneyType] = [.Agoraphobia, .GeneralAnxiety]
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Back"){
                    viewModel.previous()
                }.buttonStyle(PillButtonStyle(style: .destructive)).padding(.leading, 10)
                Spacer()
            }
            
            Spacer()
            
            
            HStack {
                Text("Choose your path").font(.title.bold()).fontDesign(.serif).padding(.leading, 10).foregroundColor(.black)
                Spacer()
            }
            
            HStack {
                Text("We have designed different activities, tools and tricks to help you get on your way to recovery. Its sometimes hard to define what that means, but we think you will find that they can be really helpful. Try and choose a path that closely resembles with your own experiences.").font(.default).fontDesign(.serif).padding(.leading, 10).foregroundColor(.black)
                Spacer()
            }.padding(.top, -20).padding(.bottom, 20)
                
            ForEach(journeyTypes, id: \.self) { type in
                if type == .Agoraphobia {
                 
                    Card(backgroundColor: Color(.yellow).opacity(0.2)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Agoraphobia")
                                    .font(.title2.bold())
                                    .fontDesign(.serif).foregroundColor(.black)
                                Spacer()
                                
                                Button("next"){
                                    viewModel.chosenJourneyType = .Agoraphobia
                                    viewModel.advance()
                                }.buttonStyle(PillButtonStyle(style: .success)).padding(.leading, 10)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.leading, 10)
                    
                } else if type == .GeneralAnxiety {
                    Card(backgroundColor: Color(.blue).opacity(0.2)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("General Anxiety")
                                    .font(.title2.bold()).foregroundColor(.black)
                                Spacer()
                                
                                Button("next"){
                                    viewModel.chosenJourneyType = .GeneralAnxiety
                                    viewModel.advance()
                                }.buttonStyle(PillButtonStyle(style: .success)).padding(.leading, 10)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.leading, 10)
                }
            }
            
            Spacer()
            
        }
    }
}

struct OnboardingDataPrivacyView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var anxietyTitle: String {
        if viewModel.chosenJourneyType == .Agoraphobia {
            "Agoraphobia"
        } else if viewModel.chosenJourneyType == .GeneralAnxiety {
            "General Anxiety"
        } else {
            "Anxiety"
        }
    }
    
    private var anxietyText: String {
        if viewModel.chosenJourneyType == .Agoraphobia {
            "Welcome. We're so glad you're here. This is a space where you can just be, without any pressure or expectation. We understand that taking even the smallest step can feel monumental, and we want you to know that you are in complete control of your journey. Here, from the comfort of your own space, you can explore tools and resources at a pace that feels right for you. Think of this as a gentle starting point, a place where your world can begin to feel a little bigger, whenever you're ready."
        } else if viewModel.chosenJourneyType == .GeneralAnxiety {
            "Welcome. We're so glad you're here. We know that sometimes thoughts can feel loud and the world can seem overwhelming. This is a space designed to help you find a moment of quiet, a place to catch your breath without any pressure or expectation. You are in complete control of your journey. Explore grounding techniques, discover helpful resources, and learn to navigate your feelings at a pace that feels comfortable for you. Think of this as your personal toolkit, a gentle space to find your center, whenever you're ready."
        } else {
            "Anxiety"
        }
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Button("Back"){
                    viewModel.previous()
                }.buttonStyle(PillButtonStyle(style: .destructive)).padding(.leading, 10)
                Spacer()
                Button("Get Started"){
                    
                    let newJourney = Journey()
                    newJourney.type = viewModel.chosenJourneyType
                    newJourney.startDate = Date()
                    newJourney.current = true
                    newJourney.isCompleted = false
                    let realm = try! Realm()
                    try! realm.write {
                        realm.add(newJourney)
                        dismiss()
                        print("Done Creating Journey")
                    }
                    
                }.buttonStyle(PillButtonStyle(style: .success)).padding(.trailing, 10)
            }
            
            Spacer()
            
            HStack {
                Text(anxietyTitle).font(.title.bold()).fontDesign(.serif).padding(.leading, 10).foregroundColor(.black)
                Spacer()
            }.padding(.top, 20)
            Spacer()
            
            Text(anxietyText).fontDesign(.serif).padding(10).foregroundColor(.black)
        }
    }
}

struct OnboardingFinishView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack {
            Text("Finish")
        }
    }
}

#Preview {
    OnboardingContainerView()
}
