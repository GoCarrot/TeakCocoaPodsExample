import Testing
import Foundation
@testable import TeakSwiftCleanroomPods

/// Tests that ActivityAttributes and ContentState types encode/decode correctly.
/// This validates the contract with APNs — if the JSON shape is wrong, push-based
/// updates will silently fail.
struct ActivityAttributesCodableTests {

    // MARK: - TimerActivityAttributes

    @Test func timerAttributesRoundTrip() throws {
        let original = TimerActivityAttributes(name: "Test Timer")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TimerActivityAttributes.self, from: data)
        #expect(decoded.name == original.name)
    }

    @Test func timerContentStateRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let original = TimerActivityAttributes.ContentState(
            endDate: Date(timeIntervalSince1970: 1700000000),
            status: "In Progress"
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TimerActivityAttributes.ContentState.self, from: data)
        #expect(decoded.endDate == original.endDate)
        #expect(decoded.status == original.status)
    }

    @Test func timerContentStateJsonShape() throws {
        let state = TimerActivityAttributes.ContentState(
            endDate: Date(timeIntervalSince1970: 1700000000),
            status: "In Progress"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        let dict = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // Verify expected keys exist
        #expect(dict["endDate"] is String, "endDate should encode as ISO 8601 string")
        #expect(dict["status"] is String)
        #expect(dict.count == 2, "ContentState should have exactly 2 fields")
    }

    @Test func timerAttributesJsonShape() throws {
        let attrs = TimerActivityAttributes(name: "My Timer")
        let data = try JSONEncoder().encode(attrs)
        let dict = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(dict["name"] as? String == "My Timer")
        #expect(dict.count == 1, "Attributes should have exactly 1 field")
    }

    // MARK: - CountdownActivityAttributes

    @Test func countdownAttributesRoundTrip() throws {
        let original = CountdownActivityAttributes(name: "Test Countdown")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CountdownActivityAttributes.self, from: data)
        #expect(decoded.name == original.name)
    }

    @Test func countdownContentStateRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let original = CountdownActivityAttributes.ContentState(
            endDate: Date(timeIntervalSince1970: 1700000000),
            phase: "Active"
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(CountdownActivityAttributes.ContentState.self, from: data)
        #expect(decoded.endDate == original.endDate)
        #expect(decoded.phase == original.phase)
    }

    @Test func countdownContentStateJsonShape() throws {
        let state = CountdownActivityAttributes.ContentState(
            endDate: Date(timeIntervalSince1970: 1700000000),
            phase: "Active"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        let dict = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(dict["endDate"] is String, "endDate should encode as ISO 8601 string")
        #expect(dict["phase"] is String)
        #expect(dict.count == 2, "ContentState should have exactly 2 fields")
    }

    // MARK: - Cross-type: schemas are distinct

    @Test func timerAndCountdownHaveDifferentSchemas() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let date = Date(timeIntervalSince1970: 1700000000)

        let timerData = try encoder.encode(
            TimerActivityAttributes.ContentState(endDate: date, status: "test")
        )
        let countdownData = try encoder.encode(
            CountdownActivityAttributes.ContentState(endDate: date, phase: "test")
        )

        let timerKeys = (try JSONSerialization.jsonObject(with: timerData) as! [String: Any]).keys.sorted()
        let countdownKeys = (try JSONSerialization.jsonObject(with: countdownData) as! [String: Any]).keys.sorted()

        // Both have endDate, but second field differs
        #expect(timerKeys.contains("status"))
        #expect(!timerKeys.contains("phase"))
        #expect(countdownKeys.contains("phase"))
        #expect(!countdownKeys.contains("status"))
    }

    // MARK: - Default date encoding (deferredToDate)

    @Test func contentStateDefaultDateEncoding() throws {
        // Without specifying a date strategy, Swift uses deferredToDate
        // (timeIntervalSinceReferenceDate as a number). This test documents
        // what the default encoding looks like, which matters for understanding
        // what APNs expects.
        let state = TimerActivityAttributes.ContentState(
            endDate: Date(timeIntervalSince1970: 1700000000),
            status: "test"
        )
        let data = try JSONEncoder().encode(state)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Default encoding: endDate is a number (timeIntervalSinceReferenceDate)
        #expect(dict["endDate"] is Double, "Default date encoding should produce a number")
    }
}
