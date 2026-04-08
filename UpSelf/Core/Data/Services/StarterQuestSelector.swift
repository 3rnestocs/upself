//
//  StarterQuestSelector.swift
//  UpSelf
//
//  Returns the hardcoded 19-quest starter set designed for the initial user profile.
//  All blueprints are defined inline (not loaded from JSON) so titles and schedules
//  can differ from the catalog (e.g. "Caminar 20 minutos" vs catalog's "Caminar 15 minutos").
//

import Foundation

enum QuestTargetDays: Int {
    case fullWeek = 7
    case workDays = 5
    case halfWeek = 3
    case weekends = 2
}

enum StarterQuestSelector {

    /// Returns the starter quest set. If `priority` is set, appends 2 extra quests for that stat.
    static func starterBlueprints(priority: CharacterAttribute? = nil) -> [BundledQuestBlueprint] {
        var blueprints = baseBlueprints()
        if let priority {
            blueprints += priorityBlueprints(for: priority)
        }
        return blueprints
    }

    // MARK: - Base set

    private static func baseBlueprints() -> [BundledQuestBlueprint] {
        [
            // ── VITALITY ──────────────────────────────────────────────────────────
            blueprint("Beber 8 vasos de agua",                    stat: .vitality, tier: .easy,    target: QuestTargetDays.fullWeek.rawValue),
            blueprint("Dormir 7 horas",                           stat: .vitality, tier: .easy,    target: QuestTargetDays.fullWeek.rawValue),
            blueprint("Caminar 20 minutos",                       stat: .vitality, tier: .easy,    target: QuestTargetDays.fullWeek.rawValue),
            blueprint("50 flexiones y 100 saltos de tijera",      stat: .vitality, tier: .regular, target: nil),

            // ── LOGISTICS ─────────────────────────────────────────────────────────
            blueprint("Planifica tu día",                         stat: .logistics, tier: .easy,   target: QuestTargetDays.workDays.rawValue),
            blueprint("Cierre del día: revisa qué completaste",   stat: .logistics, tier: .easy,   target: QuestTargetDays.workDays.rawValue),
            blueprint("Limpiar el escritorio",                    stat: .logistics, tier: .easy,   target: nil),

            // ── MASTERY ───────────────────────────────────────────────────────────
            blueprint("Estudiar 30 minutos",                      stat: .mastery, tier: .easy,     target: QuestTargetDays.workDays.rawValue),
            blueprint("Escuchar un podcast (mín. 30 min)",        stat: .mastery, tier: .easy,     target: QuestTargetDays.workDays.rawValue),
            blueprint("Practicar inglés con ELSA Speak",          stat: .mastery, tier: .easy,     target: QuestTargetDays.workDays.rawValue),

            // ── CHARISMA ──────────────────────────────────────────────────────────
            blueprint("Enviar un mensaje amable",                 stat: .charisma, tier: .easy,    target: QuestTargetDays.halfWeek.rawValue),
            blueprint("Visitar a un amigo en persona",            stat: .charisma, tier: .easy,    target: nil),

            // ── WILLPOWER ─────────────────────────────────────────────────────────
            blueprint("No revisar el móvil la primera hora",      stat: .willpower, tier: .easy,   target: QuestTargetDays.fullWeek.rawValue),
            blueprint("No ver redes sociales durante 2 horas",    stat: .willpower, tier: .easy,   target: QuestTargetDays.fullWeek.rawValue),
            blueprint("Rechazar una tentación",                   stat: .willpower, tier: .easy,   target: QuestTargetDays.fullWeek.rawValue),
            blueprint("Ducha fría",                               stat: .willpower, tier: .easy,   target: QuestTargetDays.fullWeek.rawValue),
            blueprint("No usar el celular 1 hora antes de dormir", stat: .willpower, tier: .easy,  target: nil),

            // ── ECONOMY ───────────────────────────────────────────────────────────
            blueprint("Trabaja 30 minutos en un proyecto personal", stat: .economy, tier: .regular, target: nil),
            blueprint("Aumentar tus ingresos en 10%",               stat: .economy, tier: .regular,  target: nil, isGoal: true),
        ]
    }

    // MARK: - Priority extras

    private static func priorityBlueprints(for stat: CharacterAttribute) -> [BundledQuestBlueprint] {
        switch stat {
        case .vitality:
            return [
                blueprint("Meditar 10 minutos",          stat: .vitality,  tier: .easy, target: QuestTargetDays.fullWeek.rawValue),
                blueprint("Comer sin distracciones",     stat: .vitality,  tier: .easy, target: QuestTargetDays.workDays.rawValue),
            ]
        case .mastery:
            return [
                blueprint("Leer 15 páginas",             stat: .mastery,   tier: .easy, target: QuestTargetDays.fullWeek.rawValue),
                blueprint("Practicar una habilidad 20 min", stat: .mastery, tier: .easy, target: QuestTargetDays.workDays.rawValue),
            ]
        case .charisma:
            return [
                blueprint("Llamar a alguien que importa", stat: .charisma, tier: .easy, target: QuestTargetDays.halfWeek.rawValue),
                blueprint("Asistir a un evento social",  stat: .charisma,  tier: .easy, target: nil),
            ]
        case .willpower:
            return [
                blueprint("Meditar 10 minutos",          stat: .willpower, tier: .easy, target: QuestTargetDays.fullWeek.rawValue),
                blueprint("Trabajar sin distracciones 30 min", stat: .willpower, tier: .easy, target: QuestTargetDays.workDays.rawValue),
            ]
        case .logistics:
            return [
                blueprint("Revisar tu lista de tareas",  stat: .logistics, tier: .easy, target: QuestTargetDays.fullWeek.rawValue),
                blueprint("Organizar un espacio",        stat: .logistics, tier: .easy, target: QuestTargetDays.halfWeek.rawValue),
            ]
        case .economy:
            return [
                blueprint("Revisar tu presupuesto",      stat: .economy,   tier: .easy, target: QuestTargetDays.halfWeek.rawValue),
                blueprint("Estudiar finanzas 30 min",    stat: .economy,   tier: .easy, target: QuestTargetDays.workDays.rawValue),
            ]
        }
    }

    // MARK: - Private helpers

    private static func blueprint(
        _ title: String,
        stat: CharacterAttribute,
        tier: QuestRewardTier,
        target: Int?,
        isGoal: Bool = false
    ) -> BundledQuestBlueprint {
        let definition = BundledQuestDefinition(
            title: title,
            tier: tier.rawValue,
            description: nil,
            weeklyTarget: target,
            isGoal: isGoal
        )
        return BundledQuestBlueprint(
            definition: definition,
            attribute: stat,
            rewardTier: tier
        )
    }
}
