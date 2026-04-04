//
//  HistoryLogMessageFormatterTests.swift
//  UpSelfTests
//

import Testing
@testable import UpSelf

struct HistoryLogMessageFormatterTests {

    @Test func splitXPGainMessage_splitsHeadAndStat() {
        let message = "+10 XP\nVitality"
        let split = HistoryLogMessageFormatter.splitXPGainMessage(message)
        #expect(split?.xpOrQuestLine == "+10 XP")
        #expect(split?.statLine == "Vitality")
    }

    @Test func splitXPGainMessage_trimsWhitespace() {
        let message = "  line one  \n  line two  "
        let split = HistoryLogMessageFormatter.splitXPGainMessage(message)
        #expect(split?.xpOrQuestLine == "line one")
        #expect(split?.statLine == "line two")
    }

    @Test func splitXPGainMessage_returnsNilForSingleLine() {
        #expect(HistoryLogMessageFormatter.splitXPGainMessage("only one") == nil)
    }

    @Test func splitXPGainMessage_returnsNilWhenEitherSideEmpty() {
        #expect(HistoryLogMessageFormatter.splitXPGainMessage("\nstat") == nil)
        #expect(HistoryLogMessageFormatter.splitXPGainMessage("head\n") == nil)
    }
}
