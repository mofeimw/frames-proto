//
//  FramesApp.swift
//  Frames
//
//  Created by mofei wang on 7/23/24.
//

import SwiftUI

@main
struct FramesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light)
        }
    }
}
