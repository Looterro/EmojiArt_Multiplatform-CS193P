//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by Jakub Łata on 19/12/2022.
//

import Foundation

extension EmojiArtModel {
    
    //Background is either nothing, an url that contains an downloadable image or an image in the file
    enum Background: Equatable, Codable {
        case blank
        case url(URL)
        case imageData(Data)
        
//        //Manually making Background Codable:
        
//        init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//            if let url = try? container.decode(URL.self, forKey: .url) {
//                self = .url(url)
//            } else if let imageData = try? container.decode(Data.self, forKey: .imageData) {
//                self = .imageData(imageData)
//            } else {
//                self = .blank
//            }
//
//        }
//
//        //Coding Keys allow for identifying the type, adding strings allows for renaming raw value
//        enum CodingKeys: String, CodingKey{
//            case url = "theURL"
//            case imageData
//        }
//
//        func encode(to encoder: Encoder) throws {
//            var container = encoder.container(keyedBy: CodingKeys.self)
//            switch self {
//            case .url(let url): try container.encode(url, forKey: .url)
//            case .imageData(let data): try container.encode(data, forKey: .imageData)
//            case .blank: break
//            }
//        }
        
        //Make sure that the link is a link, otherwise return a nil. Therefore its a covenience function providing an optional
        var url: URL? {
            switch self {
            case .url(let url): return url
            default: return nil
            }
        }
        
        var imageData: Data? {
            switch self {
            case .imageData(let data): return data
            default: return nil
            }
        }
        
    }
    
}
