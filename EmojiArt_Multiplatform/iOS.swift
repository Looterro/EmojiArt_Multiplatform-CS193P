//
//  iOS.swift
//  EmojiArt_Multiplatform
//
//  Created by Jakub Łata on 08/01/2023.
//

import SwiftUI

#if os(iOS)

extension UIImage {
    var imageData: Data? { jpegData(compressionQuality: 1.0 ) }
}

struct PasteBoard {
    static var imageData: Data? {
        UIPasteboard.general.image?.imageData
    }
    static var imageURL: URL? {
        UIPasteboard.general.url?.imageURL
    }
}


extension View {
    
    func paletteControlButtonStyle() -> some View {
        self
    }
    
    func popoverPadding() -> some View {
        self
    }
    
    @ViewBuilder
    func wrappedInNavigationViewToMakeDismissable (_ dismiss: (() -> Void )?) -> some View {
        //Anytime device is not ipad return self code in Navigation View
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            NavigationView {
    
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
                
            }
            //stack views on top of each other
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            
            self
            
        }
    }
    
    //function to button
    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void )?) -> some View {
        
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        } else {
            self
        }
        
    }
    
}

#endif
