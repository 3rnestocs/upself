//
//  Quest.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//


import Foundation
import SwiftData

@Model
final class Quest {
    @Attribute(.unique) var id: UUID
    var title: String
    var statType: String // Logística, Maestría, Carisma, Voluntad, Vitalidad, Economía
    var rewardXP: Int    // S=10, M=25, L=50, XL=250
    var isDaily: Bool
    var lastCompleted: Date?
    
    // Relación opcional con el Perfil (para filtrar por usuario si fuera necesario)
    var user: UserProfile?

    init(id: UUID = UUID(), 
         title: String, 
         statType: String, 
         rewardXP: Int = 25, 
         isDaily: Bool = true) {
        self.id = id
        self.title = title
        self.statType = statType
        self.rewardXP = rewardXP
        self.isDaily = isDaily
    }
}