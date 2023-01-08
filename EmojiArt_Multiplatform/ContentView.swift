//
//  ContentView.swift
//  EmojiArt_Multiplatform
//
//  Created by Jakub Łata on 08/01/2023.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: EmojiArt_MultiplatformDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(EmojiArt_MultiplatformDocument()))
    }
}
