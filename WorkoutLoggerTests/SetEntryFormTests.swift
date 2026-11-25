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

    func testPrefillShowsWeightAndRepsHintOnly() {
        var form = SetEntryForm(prefill: SetPrefill(weight: 80, repsHint: 10, field: .reps))
        XCTAssertEqual(form.weightText, "80")
        XCTAssertEqual(form.repsText, "", "reps are not filled in")
        XCTAssertEqual(form.repsHint, 10)
        XCTAssertEqual(form.field, .reps)
        XCTAssertNil(form.values, "Save stays disabled until reps are typed")
        type([.digit(9)], into: &form)
        XCTAssertEqual(form.values, SetValues(weight: 80, reps: 9))

        let empty = SetEntryForm(prefill: SetPrefill(weight: nil, repsHint: nil, field: .weight))
        XCTAssertEqual(empty.weightText, "")
        XCTAssertEqual(empty.field, .weight)
    }

    func testDoubleSavesTotalAndTypingClearsIt() {
        var form = SetEntryForm(prefill: SetPrefill(weight: 22.5, repsHint: nil, field: .reps))
        form.toggleDouble()
        XCTAssertTrue(form.isDoubled)
        XCTAssertEqual(form.weightText, "45")
        type([.digit(8)], into: &form)
        XCTAssertTrue(form.isDoubled, "typing reps keeps it")
        XCTAssertEqual(form.values?.weight, 45, "the doubled total is saved")

        form.select(.weight)
        type([.digit(5), .digit(0)], into: &form)
        XCTAssertFalse(form.isDoubled, "typing in Weight clears it")
        XCTAssertEqual(form.weight, 50)
    }

    func testDoubleTwiceRestoresPerSideAndEmptyDoesNothing() {
        var form = SetEntryForm(prefill: SetPrefill(weight: 12.5, repsHint: nil, field: .reps))
        form.toggleDouble()
        form.toggleDouble()
        XCTAssertFalse(form.isDoubled)
        XCTAssertEqual(form.weightText, "12.5")
        var empty = SetEntryForm()
        empty.toggleDouble()
        XCTAssertFalse(empty.isDoubled)
        XCTAssertEqual(empty.weightText, "")
    }

    func testEditKeepsTypeAndRIR() {
        let form = SetEntryForm(initial: SetValues(weight: 60, reps: 12, rir: 2, type: .drop))
        XCTAssertEqual(form.values, SetValues(weight: 60, reps: 12, rir: 2, type: .drop))
    }
}
