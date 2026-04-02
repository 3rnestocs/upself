//
//  StatProgression.swift
//  UpSelf
//
//  Shared level / bar math for `CharacterStat.currentXP` (thresholds grow each level).
//

import Foundation

enum StatProgression {
    /// Progress units required for the first level-up (1 → 2). Five easy missions at 6 = 30.
    static let baseThreshold = 30
    /// Each subsequent segment requires this factor more than the previous threshold.
    static let growthFactor = 1.2

    static func level(forTotalXP currentXP: Int) -> Int {
        segmentState(forTotalXP: currentXP).level
    }

    /// 0…1 progress within the current segment toward the next level.
    static func progressFraction(forTotalXP currentXP: Int) -> Double {
        let s = segmentState(forTotalXP: currentXP)
        guard s.xpNeededForNext > 0 else { return 0 }
        return Double(s.xpIntoSegment) / Double(s.xpNeededForNext)
    }

    private static func segmentState(forTotalXP currentXP: Int) -> (level: Int, xpIntoSegment: Int, xpNeededForNext: Int) {
        var level = 1
        var xpLeft = max(0, currentXP)
        var needed = baseThreshold
        while xpLeft >= needed {
            level += 1
            xpLeft -= needed
            needed = max(1, Int(Double(needed) * growthFactor))
        }
        return (level, xpLeft, needed)
    }
}
