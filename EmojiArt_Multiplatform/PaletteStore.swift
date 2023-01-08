//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by Jakub Łata on 03/01/2023.
//

import SwiftUI

struct Palette: Identifiable, Codable, Hashable {
    var name: String
    var emojis: String
    var id: Int
    
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
    
}

class PaletteStore: ObservableObject {
    let name: String
    
    @Published var palettes = [Palette]() {
        didSet {
            storeInUserDefaults()
        }
    }
    
    private var userDefaultsKey: String {
        "PaletteStore:" + name
    }
    
    private func storeInUserDefaults() {
        //using data type for property list
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
        //ALTERNATIVE ineffective OPTION changing palettes to property list using map so it conforms to the older format of user defaults that are pre-swift
//        UserDefaults.standard.set( palettes.map {[$0.name, $0.emojis, String($0.id)] }, forKey: userDefaultsKey)
    }
    
    private func retoreFromUserDefaults() {
        
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey), let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData) {
            palettes = decodedPalettes
        }

        //ALTERNATIVE ineffective OPTION
        //if there is an array for given key return it as an array of Strings. You have to do it because otherwise it will return an array of Any, which is not really compatible with Swift
//        if let palettesAsPropertyList = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String]] {
//            for paletteAsArray in palettesAsPropertyList {
//                if paletteAsArray.count == 3, let id = Int(paletteAsArray[2]), !palettes.contains(where: { $0.id == id}) {
//                   let palette = Palette(name: paletteAsArray[0], emojis: paletteAsArray[1], id: id)
//                    palettes.append(palette)
//                }
//            }
//        }
    }
    
    init(named name: String) {
        self.name = name
        retoreFromUserDefaults()
        
        if palettes.isEmpty {
            print("Using built-in paletts")
            insertPalette(named: "Vehicles", emojis: "🚍🚎🚗🚛🚖")
            insertPalette(named: "Sports", emojis: "⚽️🏀🏈🥎🏓")
        } else {
            print("successfully loaded palettes from UserDefaults: \(palettes)")
        }
    }
    
    //MARK: - Intent
    
    //get a palette at a certain index. If requresting for a palette out of range it returns something within range
    func palette(at index: Int) -> Palette {
        let safeIndex = min(max(index, 0), palettes.count - 1)
        return palettes[safeIndex]
    }
    
    //doesnt allow for removing palette file if there is only one left
    @discardableResult
    func removePalette(at index: Int) -> Int {
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }
    
    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        let unique = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: unique)
        let safeIndex = min(max(index, 0), palettes.count)
        palettes.insert(palette, at: safeIndex)
    }
    
}
