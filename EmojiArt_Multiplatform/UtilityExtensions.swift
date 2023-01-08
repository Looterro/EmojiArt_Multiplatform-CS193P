//
//  UtilityExtensions.swift
//  EmojiArt
//
//  Created by Jakub Łata on 19/12/2022.
//

import SwiftUI


//extending the collection of identifaiables with function index that looks for first index where element has the same id as the one we are looking for. Self.Index is referenced because in collection index is identifiable, not an int(cause there might be strings in collection)
extension Collection where Element: Identifiable {
    func index(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

extension Character {
    var isEmoji: Bool {
        if let firstScalar = unicodeScalars.first, firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238d || unicodeScalars.count > 1)
        } else {
            return false
        }
    }
}

//Allowing for manipulating sizes together on the right and left side
extension CGSize {
    // the center point of an area that is our size
    var center: CGPoint {
        CGPoint(x: width/2, y: height/2)
    }
    static func +(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
}


//EXTENSION ON URL TYPE, allows for checking whether the link is longer than the path of the image itself(it includes for example the path of the company page providing it). It then strips down the link to be only an image path
extension URL {
    var imageURL: URL {
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                    return url
                }
            }
        }
        
        return baseURL ?? self
    }
}

//extension for drag and drop functionality for array
extension Array where Element == NSItemProvider {
    
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, error in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
                
            }
            return true
        }
        return false
    }
    
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            let _ = provider.loadObject(ofClass: theType) { object, error in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    
}

// some extensions to String and Character
// to help us with managing our Strings of emojis
// we want them to be "emoji only"
// (thus isEmoji below)
// and we don't want them to have repeated emojis
// (thus withoutDuplicateCharacters below)

extension String {
    var removingDuplicateCharacters: String {
        reduce(into: "") { sofar, element in
            if !sofar.contains(element) {
                sofar.append(element)
            }
        }
    }
}

// we could do the same thing when it comes to removing an element
// but we have to add that to a different protocol
// because Collection works for immutable collections of things
// the "mutable" one is RangeReplaceableCollection
// not only could we add remove
// but we could add a subscript which takes a copy of one of the elements
// and uses its Identifiable-ness to subscript into the Collection
// this is an awesome way to create Bindings into an Array in a ViewModel
// (since any Published var in an ObservableObject can be bound to via $)
// (even vars on that Published var or subscripts on that var)
// (or subscripts on vars on that var, etc.)

extension RangeReplaceableCollection where Element: Identifiable {
    mutating func remove(_ element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        }
    }

    subscript(_ element: Element) -> Element {
        get {
            if let index = index(matching: element) {
                return self[index]
            } else {
                return element
            }
        }
        set {
            if let index = index(matching: element) {
                replaceSubrange(index...index, with: [newValue])
            }
        }
    }
}

// add RawRepresentable protocol conformance to CGSize and CGFloat
// so that they can be used with @SceneStorage
// we do this by first providing default implementations of rawValue and init(rawValue:)
//   in RawRepresentable when the thing in question is Codable (which both CGFloat and CGSize are)
// then all it takes to make something that is Codable be RawRepresentable is to declare it to be so
// (it will then get the default implementions needed to be a RawRepresentable)

extension RawRepresentable where Self: Codable {
    public var rawValue: String {
        if let json = try? JSONEncoder().encode(self), let string = String(data: json, encoding: .utf8) {
            return string
        } else {
            return ""
        }
    }
    public init?(rawValue: String) {
        if let value = try? JSONDecoder().decode(Self.self, from: Data(rawValue.utf8)) {
            self = value
        } else {
            return nil
        }
    }
}

extension CGSize: RawRepresentable { }
extension CGFloat: RawRepresentable { }

