//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Jakub Łata on 19/12/2022.
//

import Foundation

struct EmojiArtModel: Codable {
    //Start background as blank
    var background = Background.blank
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        let id: Int
        
        //make sure no-one can create emojis except the developer using this code and file, thanks to fileprivate naming
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
   
    //throws is informing that it can throw an error that should be handled after the function call, but it is not pre-specified here what is should do in that situation
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    //initialize without anything to make sure no-one can initialize emojiArtModel with an outer background or emoji
    init() {}
    
    private var uniqueEmojiId = 0
    //function adding emoji to the background. Arguments specify what emoji is added, and at which location(using a tuple of coordinates) and size
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
}
