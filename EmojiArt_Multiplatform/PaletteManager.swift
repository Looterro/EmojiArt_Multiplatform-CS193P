//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Jakub Łata on 04/01/2023.
//

import SwiftUI

#if os(iOS)
struct PaletteManager: View {
    
    @EnvironmentObject var store: PaletteStore
    //get the environment variable, for example color scheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        
        //NavigationView allows for Navigation Links
        NavigationView {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
                        VStack (alignment: .leading) {
                            //if in editing mode, make titles bigger
                            Text(palette.name)/*.font(editMode == .active ? .largeTitle : .caption)*/
                            Text(palette.emojis)
                        }
                        //do gesture if in edit mode, otherwise inactive
                        .gesture(editMode == .active ? tap : nil)
                    }
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes")
            //switch title to a smaller one in the view
            .navigationBarTitleDisplayMode(.inline)
            //dismiss button
            .dismissable { presentationMode.wrappedValue.dismiss() }
            //add edit button in the upper right corner
            .toolbar {
                //discover whether the toolbar item is presented to the user
                ToolbarItem { EditButton() }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    //if the device is not Ipad, then present a close button
//                    if presentationMode.wrappedValue.isPresented/*, UIDevice.current.userInterfaceIdiom != .pad*/ {
//                        Button("Close") {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    }
//                }
            }
            //then use environment to control whether the view is in edit mode or not
            .environment(\.editMode, $editMode)
        }
    }
    
    var tap: some Gesture {
        TapGesture().onEnded {
            print("tap")
        }
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .previewDevice("iPhone SE (3rd generation)")
            .environmentObject(PaletteStore(named: "Preview"))
        //set default color scheme for the view
            .preferredColorScheme(.light)
    }
}
#endif
