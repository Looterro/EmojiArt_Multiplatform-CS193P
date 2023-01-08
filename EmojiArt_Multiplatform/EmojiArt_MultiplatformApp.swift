//
//  EmojiArt_MultiplatformApp.swift
//  EmojiArt_Multiplatform
//
//  Created by Jakub Łata on 08/01/2023.
//

import SwiftUI

@main
struct EmojiArt_MultiplatformApp: App {
    @StateObject var paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        
        DocumentGroup(newDocument: {EmojiArtDocument()} ) { config in /*config has viewModel we want to use and url to file*/
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStore)
            //fixes double back buttons
                .toolbarRole(.automatic)
        }
        
    }
    
}
