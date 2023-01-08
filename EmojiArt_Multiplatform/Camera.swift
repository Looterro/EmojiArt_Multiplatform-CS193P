//
//  Camera.swift
//  EmojiArt
//
//  Created by Jakub Łata on 07/01/2023.
//

import SwiftUI

#if os(iOS)
//function to call camera, its a view. Its type is UIKit
struct Camera: UIViewControllerRepresentable {
    
    //when the camera takes the picture it call this closure
    var handlePickedImage: (UIImage?) -> Void
    
    //check if camera is available, its not on the simulator
    static var isAvailable: Bool {
        //UIkit
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage)
    }
    
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        //nothing to do here, image is taken
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var handlePickedImage: (UIImage?) -> Void
        
        init(handlePickedImage: @escaping (UIImage?) -> Void) {
            self.handlePickedImage = handlePickedImage
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            handlePickedImage(nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            handlePickedImage((info[.editedImage] ?? info[.originalImage]) as? UIImage)
        }
        
    }

}
#endif
