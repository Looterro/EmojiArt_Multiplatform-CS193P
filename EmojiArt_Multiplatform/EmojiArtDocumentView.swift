//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Jakub Łata on 19/12/2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    //get the undoManager from the environment that is included in the View
    @Environment(\.undoManager) var undoManager
    
    //Scaled Metric allows for adjusting the text to accessibility features on iOS - if someone uses bigger text this scales up accordingly
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                //OptionalImage is a special function in utility views that alows for unwrapping the background image or not breaking the code if there is none
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojiCoordinates((0,0), in: geometry))
                
                .gesture(doubleTapToZoom(in: geometry.size))
                //if we are fetching data display progress view(the spinning wheel), and not display emojis until set. Make it bigger with scale effect
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView()
                        .scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            //doesnt let background to go over other containers, in this example the pallete
            .clipped()
            //we want to drop only plain text so that is what is of.
            .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            //never put two gestures seperately on one view! use .simultaneously(with: ) to track both of them at the same time. .exclusively works before the other one, preventing the other from firing
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            
            }
            //on receive of the published object, size the screen to fit in image, by zooming in or out
            .onReceive(document.$backgroundImage) { image in
                if autozoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {

                AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                //If camera is available, not on simulator
                if Camera.isAvailable {
                    AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                #if os(iOS)
                if let undoManager = undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    if undoManager.canRedo {
                        AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                            undoManager.redo()
                        }
                    }
                }
                #endif
                
            }
            // pull up camera view
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundimage(image) })
                case .library: PhotoLibrary(handlePickedImage: {image in handlePickedBackgroundimage(image) })
                }
            }
        }
    }
    
    
    // MARK: - Camera
    
    private func handlePickedBackgroundimage (_ image: UIImage?) {
        autozoom = true
        
        //on ios jpeg representation, on macos tif representation, all hidden in imageData variable
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        //make the camera go away
        backgroundPicker = nil
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: Identifiable {
        case camera
        case library
        var id: BackgroundPickerType { self }
    }
    
    // MARK: - Paste background
    
    private func pasteBackground() {
        autozoom = true
        if let imageData = PasteBoard.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        } else if let url = PasteBoard.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert(
                title: "Paste Background",
                message: "There is no image currently on the pasteboard."
            )
        }
    }
    
    // MARK: - Autozoom
    
    @State private var autozoom = false
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)."),
                dismissButton: .default(Text("ok"))
            )
        })
    }
    
    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        
        // see if dropped object is a url
        var found = providers.loadObjects(ofType: URL.self) { url in
            
            //turns autozoom on to fit the canvas to picture borders
            autozoom = true
            //imageURL is an extension that makes sure that link is an image, cause sometimes its a double url, that contains the owner site and then the path of the image. ImageURL in utility extensions
            document.setBackground(EmojiArtModel.Background.url(url.imageURL), undoManager: undoManager)
        }
        
        //If not found and url then try this code, look for an image, and then for a string
        // macOS NSImage does not have an NSItemProvider
        #if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autozoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        #endif
        
        if !found {
            //see if those providers have a string, the function is in extensions in utility extensions and operates on objective C language. It does everything asynchronously in order not to break the main thread. It checks whether or not object could be found
            found = providers.loadObjects(ofType: String.self) { string in
                //isEmoji is a function in extensions that checks if the emoji is indeed an emoji
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji), at: convertToEmojiCoordinates(location, in: geometry), size: defaultEmojiFontSize / zoomScale, undoManager: undoManager )
                }
            }
        }
        
        return found
    }
    
    //MARK: - Positioning/Sizing Emoji
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        
        let center = geometry.frame(in: .local).center
        
        let location = CGPoint(
            //keep track if a picture was dragged or zoomed with panOffset and zoomScale
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        
        //get the geometry center. everything is positioned from the center of the view in this case
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    //MARK: - PANNING
    
    //Panning around = drag around. When not panning the var is zero
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset") private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        // you cannot add sizes by default, therefore there is an extension in utility extensions to handle adding. zoomScale adds additional dimention if we are already zoomed in
        ( steadyStatePanOffset + gesturePanOffset ) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ /*(transaction)*/ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                //translation is a special function that can be called on the argument to the closure in this partricular case that returns the distance the finger followed from the start position. Next we are /dividing that by scale we are zoomed in and adding it to already set orientation on the screen
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    //MARK: - ZOOM
    
    //contemporary state that by default sets the scaling of background image to 1, works with double tap
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale") private var steadyStateZoomScale: CGFloat = 1
    //gesture state which changes as the pinching changes
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        //zoom scale changes as pinch gesture changes, by default 1* 1 =1
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        //for pinching gesture
        MagnificationGesture()
        //$gesturezoomscale is what we track during the gesture. latestGestureScale is the latest value telling how far are fingers apart(constantly updating), gestureZoomScale(ourGestureStateInOut) updates the @GestureState gestureZoomScale
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
        //gestureScaleAtEnd is a special argument to this function, which tells how far are the fingers comapred to the beginning of the gesture
            .onEnded{ gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom (in size: CGSize) -> some Gesture {
        //double tap on ended does the zoom to fit background picture. Its a discreet gesture
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            //get the size difference between image and container size
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            //if dragged before, double tapping sets panOffset back to zero to center image
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
