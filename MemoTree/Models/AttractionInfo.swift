//
//  AttractionInfo.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import Foundation
import CoreLocation

struct AttractionInfo: Identifiable, Codable {
    let id = UUID()
    let name: String
    let chineseName: String
    let description: String
    let history: String
    let features: [String]
    let visitTips: [String]
    let coordinates: CLLocationCoordinate2D
    let category: String
    let rating: Double
    let imageUrl: String
    
    // 自定义编码
    enum CodingKeys: String, CodingKey {
        case name, chineseName, description, history, features, visitTips, category, rating, imageUrl
        case latitude, longitude
    }
    
    init(name: String, chineseName: String, description: String, history: String, features: [String], visitTips: [String], coordinates: CLLocationCoordinate2D, category: String, rating: Double, imageUrl: String) {
        self.name = name
        self.chineseName = chineseName
        self.description = description
        self.history = history
        self.features = features
        self.visitTips = visitTips
        self.coordinates = coordinates
        self.category = category
        self.rating = rating
        self.imageUrl = imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        chineseName = try container.decode(String.self, forKey: .chineseName)
        description = try container.decode(String.self, forKey: .description)
        history = try container.decode(String.self, forKey: .history)
        features = try container.decode([String].self, forKey: .features)
        visitTips = try container.decode([String].self, forKey: .visitTips)
        category = try container.decode(String.self, forKey: .category)
        rating = try container.decode(Double.self, forKey: .rating)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(chineseName, forKey: .chineseName)
        try container.encode(description, forKey: .description)
        try container.encode(history, forKey: .history)
        try container.encode(features, forKey: .features)
        try container.encode(visitTips, forKey: .visitTips)
        try container.encode(category, forKey: .category)
        try container.encode(rating, forKey: .rating)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(coordinates.latitude, forKey: .latitude)
        try container.encode(coordinates.longitude, forKey: .longitude)
    }
} 