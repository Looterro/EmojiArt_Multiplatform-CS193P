//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Jakub Łata on 04/01/2023.
//

import SwiftUI

struct PaletteChooser: View {
    
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font { .system(size: emojiFontSize) }
    
    @EnvironmentObject var store: PaletteStore
    
    //Allows for preserving the information about the last session, so if the app is killed, the chosen palette will be saved
    @SceneStorage("PaletteChooser.chosenPaletteIndex") private var chosenPaletteIndex = 0
    
    var body: some View {
        HStack {
            paletteControlButton
            body(for: store.palette(at: chosenPaletteIndex))
        }
        .clipped()
    }
    
    var paletteControlButton: some View {
        Button {
            withAnimation {
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont)
        //change button to be more in line with the context menu
        .paletteControlButtonStyle()
        //add context menu after long pressing on the icon
        .contextMenu { contextMenu }
    }
    
    @ViewBuilder
    var contextMenu: some View {
        AnimatedActionButton(title: "Edit", systemImage: "pencil") {
            paletteToEdit = store.palette(at: chosenPaletteIndex)

        }
        AnimatedActionButton(title: "New", systemImage: "plus") {
            store.insertPalette(named: "New", emojis: "", at: chosenPaletteIndex)
            paletteToEdit = store.palette(at: chosenPaletteIndex)

        }
        AnimatedActionButton(title: "Delete", systemImage: "minus.circle") {
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        
        #if os(iOS)
        AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
            managing = true
        }
        #endif
        
        gotoMenu
    }
    
    var gotoMenu: some View {
        Menu {
            ForEach (store.palettes) { palette in
                AnimatedActionButton(title: palette.name) {
                    if let index = store.palettes.index(matching: palette) {
                        chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
        }
    }
    
    func body(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojisView(emojis: palette.emojis)
                .font(emojiFont)
        }
        //adding id to make the view identifiable, if it changes, the whole HStack changes, which allows for transition to work on an entire stack and not just the emojis
        .id(palette.id)
        .transition(rollTransition)
        //.sheet is for a new blank view over the view, .popover is the same but smaller and with arrow pointing at origin. The other option is using nil or object method instead of false/true
        .popover(item: $paletteToEdit) { palette in
            PaletteEditor(palette: $store.palettes[palette])
            //on mac add padding
                .popoverPadding()
                .wrappedInNavigationViewToMakeDismissable { paletteToEdit = nil }
        }
        .sheet(isPresented: $managing) {
            PaletteManager()
        }
    }
    

    
    @State private var managing = false
    @State private var paletteToEdit: Palette?
    
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric(insertion: .offset(x: 0, y: emojiFontSize), removal: .offset(x: 0, y: -emojiFontSize))
    }

}

struct ScrollingEmojisView: View {

    let emojis: String

    var body: some View {
        
        ScrollView(.horizontal) {
            HStack {
                //map all emojis and stringify them
                ForEach(emojis.removingDuplicateCharacters.map {String($0)}, id: \.self ) { emoji in
                    Text(emoji)
                    //using ns item as a ns string(objective c naming) to put it somewhere else
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }

}
