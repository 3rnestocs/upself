//
//  UserProfile.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//


import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var currentHP: Int
    var maxHP: Int
    var lastAppOpen: Date
    var isInLockdown: Bool
    
    @Relationship(deleteRule: .cascade) 
    var stats: [CharacterStat] = []

    @Relationship(deleteRule: .cascade, inverse: \Quest.user)
    var quests: [Quest] = []

    init(id: UUID = UUID(), 
         currentHP: Int = 100, 
         maxHP: Int = 100, 
         lastAppOpen: Date = .now, 
         isInLockdown: Bool = false) {
        self.id = id
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.lastAppOpen = lastAppOpen
        self.isInLockdown = isInLockdown
    }
}
