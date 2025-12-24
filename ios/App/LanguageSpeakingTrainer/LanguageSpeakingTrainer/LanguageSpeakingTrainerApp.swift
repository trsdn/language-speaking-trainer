//
//  LanguageSpeakingTrainerApp.swift
//  LanguageSpeakingTrainer
//
//  Created by Torsten Mahr on 23.12.25.
//

import SwiftUI

@main
struct LanguageSpeakingTrainerApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}
