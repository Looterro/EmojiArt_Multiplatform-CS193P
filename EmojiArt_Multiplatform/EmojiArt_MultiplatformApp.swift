//
//  EmojiArt_MultiplatformApp.swift
//  EmojiArt_Multiplatform
//
//  Created by Jakub Łata on 08/01/2023.
//

import SwiftUI

@main
struct EmojiArt_MultiplatformApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: EmojiArt_MultiplatformDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
