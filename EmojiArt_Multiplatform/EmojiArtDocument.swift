//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Jakub Łata on 19/12/2022.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

//Extending UTTypes (like mp3, png) with our own file type
extension UTType {
    static let emojiart = UTType(exportedAs: "Lata-Jakub.developer.EmojiArt")
}

//ReferenceFileDocument contains ObservableObject
class EmojiArtDocument: ReferenceFileDocument {
    
    //UTType requires importing UniformTypeIdentifiers
    static var readableContentTypes = [UTType.emojiart]
    static var writableContentTypes = [UTType.emojiart]
    
    //initialize the document, getting data through jason and fetching background image
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        } else {
            //throw an error that the file is corrupted
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    //How do we represent this document as a data, in this case its json
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    //Regular file with some contents that is wrapped after snapshot call for autosave
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    // MARK: - Model
    
    
    @Published private(set) var emojiArt: EmojiArtModel {
        //If something changed to the model (didSet):
        didSet {
            //change the background when we apply a new background through drag and drop
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    
    init() {
        
        emojiArt = EmojiArtModel()

    }
    
    //MARK: - Get background image
    
    //convenience functions to get background and emojis from model
    var emojis: [EmojiArtModel.Emoji] {emojiArt.emojis}
    var background: EmojiArtModel.Background {emojiArt.background}
    
    //Make background image published to keep track as it changes. We have to return an optional cause it might be not an image but nil. Therefore when unwrapping we need special function in the view
    @Published var backgroundImage: UIImage?
    
    //Give user some feedback when offloading background image from drag and drop. Start in the idle state
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    //In order to use we need to import Combine
    private var backgroundImageFetchCancellable: AnyCancellable?
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
            
        case .url(let url):
            
            // change the information status to fetching
            backgroundImageFetchStatus = .fetching
            
            //cancel any other fetches
            backgroundImageFetchCancellable?.cancel()
            
            //URLSession.shared looks up something in the internet and lets you know when it returns data
            let session = URLSession.shared
            //map the data that is returned in the tuple and return an UIImage
            let publisher = session.dataTaskPublisher(for: url)
                .map { (data, URLResponse) in UIImage(data: data) }
                //dont report an error, convert it to nil
                .replaceError(with: nil)
            //return the picture to the main queue
                .receive(on: DispatchQueue.main)
            
            //apply the image to background image. It will hold onto backgroundImageFetchCancellable as long as it needs
            backgroundImageFetchCancellable = publisher
                
                .sink { [weak self] image in
                    self?.backgroundImage = image
                    //update the fetching status
                    self?.backgroundImageFetchStatus = (image != nil ) ? .idle : .failed(url)
                }
            
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    //MARK: - Intents
    
    //UndoManager lives in the view so it must be passed from there to the function
    func setBackground(_ background: EmojiArtModel.Background, undoManager: UndoManager?) {
        undoablyPerform(operation: "Set Background", with: undoManager) {
            emojiArt.background = background
        }
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
        undoablyPerform(operation: "Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(emoji, at: location, size: Int(size))
        }
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero  ))
            }
        }
    }
    
    func removeEmoji(_ emoji: EmojiArtModel.Emoji) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis.remove(at: index)
        }
    }
    
    // MARK: - Undo
    
    //undo function, save old state in oldEmojiArt, do the action and then register undo and perform going back to former state
    private func undoablyPerform(operation: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        //do the action that is assigned to it
        doit()
        //myself is the current state
        undoManager?.registerUndo(withTarget: self) { myself in
            //include redo by doing undo undoable   
            myself.undoablyPerform(operation: operation, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        //set the name of the operation for a specific undoable thing
        undoManager?.setActionName(operation)
    }
    
}
