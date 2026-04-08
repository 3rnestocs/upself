//
//  Calendar+Week.swift
//  UpSelf
//
//  Week-boundary helpers used by Quest scheduling and penalty evaluation.
//

import Foundation

extension Calendar {

    /// Returns the start of the Monday (00:00 local time) for the week that contains `date`.
    /// Uses ISO weekday numbering (1 = Sunday, 2 = Monday … 7 = Saturday) which is locale-independent.
    func mondayStart(for date: Date) -> Date {
        let weekday = component(.weekday, from: date)   // 1=Sun 2=Mon … 7=Sat
        let daysFromMonday = (weekday + 5) % 7          // Mon→0, Tue→1, … Sun→6
        let monday = self.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        return startOfDay(for: monday)
    }

    /// `true` if `date` falls on a Monday in this calendar.
    func isMonday(_ date: Date) -> Bool {
        component(.weekday, from: date) == 2
    }
}
