import XCTest
@testable import WorkoutLogger

final class SetEntryFormTests: XCTestCase {
    private func type(_ keys: [KeypadKey], into form: inout SetEntryForm) {
        keys.forEach { form.press($0) }
    }

    func testPrefilledFormSavesAsIsAndStartsOnReps() {
        let form = SetEntryForm(initial: SetValues(weight: 80, reps: 8))
        XCTAssertEqual(form.field, .reps)
        XCTAssertEqual(form.values, SetValues(weight: 80, reps: 8, rir: nil))
    }

    func testEmptyFormStartsOnWeightAndIsInvalid() {
        let form = SetEntryForm()
        XCTAssertEqual(form.field, .weight)
        XCTAssertNil(form.values)
    }

    func testFirstDigitReplacesPrefilledValue() {
        var form = SetEntryForm(initial: SetValues(weight: 80, reps: 8))
        type([.digit(1), .digit(0)], into: &form)
        XCTAssertEqual(form.repsText, "10")
        form.select(.weight)
        type([.digit(8), .digit(2), .decimal, .digit(5)], into: &form)
        XCTAssertEqual(form.weight, 82.5)
    }

    func testWeightLimits() {
        var form = SetEntryForm()
        type([.decimal, .digit(5)], into: &form)
        XCTAssertEqual(form.weightText, "0.5")
        type([.decimal, .digit(2), .digit(5)], into: &form)
        XCTAssertEqual(form.weightText, "0.52", "one decimal point, max 2 decimals")
        form.select(.weight)
        type([.digit(1), .digit(2), .digit(3), .digit(4), .digit(5)], into: &form)
        XCTAssertEqual(form.weightText, "1234")
        type([.backspace], into: &form)
        XCTAssertEqual(form.weightText, "123")
    }

    func testRepsIgnoreDecimalAndLeadingZero() {
        var form = SetEntryForm(field: .reps)
        type([.digit(0), .digit(5), .decimal, .digit(1), .digit(2), .digit(3)], into: &form)
        XCTAssertEqual(form.repsText, "512")
        form.select(.reps)
        type([.digit(0)], into: &form)
        XCTAssertNil(form.reps, "0 reps is invalid")
    }

    func testRIRSingleDigitZeroToFiveAndClearable() {
        var form = SetEntryForm(initial: SetValues(weight: 50, reps: 10))
        form.select(.rir)
        type([.digit(7)], into: &form)
        XCTAssertNil(form.rir)
        type([.digit(3)], into: &form)
        XCTAssertEqual(form.rir, 3)
        type([.digit(0)], into: &form)
        XCTAssertEqual(form.rir, 0)
        type([.backspace], into: &form)
        XCTAssertNil(form.rir)
        XCTAssertNotNil(form.values, "RIR is optional")
    }

    func testStepWeight() {
        var form = SetEntryForm(initial: SetValues(weight: 80, reps: 8))
        form.stepWeight(by: 2.5, up: true)
        XCTAssertEqual(form.weightText, "82.5")
        form.stepWeight(by: 100, up: false)
        XCTAssertEqual(form.weight, 0)
        var empty = SetEntryForm()
        empty.stepWeight(by: 5, up: true)
        XCTAssertEqual(empty.weight, 5)
    }

    func testEditKeepsTypeAndRIR() {
        let form = SetEntryForm(initial: SetValues(weight: 60, reps: 12, rir: 2, type: .drop))
        XCTAssertEqual(form.values, SetValues(weight: 60, reps: 12, rir: 2, type: .drop))
    }
}
