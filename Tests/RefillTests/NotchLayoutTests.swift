import XCTest
@testable import Refill

final class NotchLayoutTests: XCTestCase {
    func testSixteenInchFlanksTheMeasuredHousing() throws {
        let screen = DisplayGeometry.macBookPro16
        let notch = try XCTUnwrap(screen.notchRect)
        XCTAssertEqual(notch.width, 220, accuracy: 0.01)
        XCTAssertEqual(notch.height, 38, accuracy: 0.01)

        let layout = NotchLayout.resolve(screen)
        guard case .flank(let ear, let gap) = layout.placement else {
            return XCTFail("expected the wings to flank a 38pt housing")
        }
        XCTAssertEqual(gap, 220, accuracy: 0.01)
        XCTAssertEqual(ear, NotchMetrics.ear, accuracy: 0.01)
        XCTAssertEqual(layout.openSize.height, screen.safeAreaTop, accuracy: 0.01)
        XCTAssertEqual(layout.openSize.width, gap + ear * 2, accuracy: 0.01)
        XCTAssertLessThan(layout.openSize.height, 50, "the old banner was 86pt and grew from there")
        XCTAssertEqual(layout.openOffset, 0, accuracy: 0.01)
        XCTAssertEqual(layout.panelFrame.maxY, screen.frame.maxY, accuracy: 0.01)
        assertMissesHousing(layout, notch)
        assertInLobes(layout, screen, notch)
        assertInsidePanel(layout)
        assertRoundTrip(layout)
    }

    func testFourteenInchFlanksAndStaysOffTheCamera() throws {
        let screen = DisplayGeometry.macBookPro14
        let layout = NotchLayout.resolve(screen)
        let notch = try XCTUnwrap(layout.notchRect)
        XCTAssertEqual(notch.width, 184, accuracy: 0.01)
        XCTAssertEqual(layout.openSize.height, 32, accuracy: 0.01)
        guard case .flank = layout.placement else { return XCTFail("expected flank") }
        assertMissesHousing(layout, notch)
        let icon = layout.globalFrame(layout.iconFrame)
        let text = layout.globalFrame(layout.textFrame)
        XCTAssertLessThanOrEqual(icon.maxX, notch.minX - NotchMetrics.housingGap + 0.6)
        XCTAssertGreaterThanOrEqual(text.minX, notch.maxX + NotchMetrics.housingGap - 0.6)
        XCTAssertGreaterThanOrEqual(layout.panelFrame.minX, screen.frame.minX + NotchMetrics.edgeReserve - 0.6)
        XCTAssertLessThanOrEqual(layout.panelFrame.maxX, screen.frame.maxX - NotchMetrics.edgeReserve + 0.6)
    }

    func testFlankHeightFollowsSafeAreaAndWidthFollowsTheGap() {
        var taller = DisplayGeometry.macBookPro14
        taller.safeAreaTop = 36
        let tall = NotchLayout.resolve(taller)
        XCTAssertEqual(tall.openSize.height, 36, accuracy: 0.01)

        var wider = DisplayGeometry.macBookPro16
        wider.auxiliaryTopLeft?.size.width -= 15
        wider.auxiliaryTopRight?.origin.x += 15
        let base = NotchLayout.resolve(.macBookPro16)
        let grown = NotchLayout.resolve(wider)
        XCTAssertEqual(grown.notchRect?.width ?? 0, 250, accuracy: 0.01)
        XCTAssertEqual(grown.openSize.width - base.openSize.width, 30, accuracy: 0.01)
        XCTAssertEqual(grown.openSize.height, base.openSize.height, accuracy: 0.01)
    }

    func testLayoutDoesNotDependOnTheMessage() {
        XCTAssertEqual(NotchLayout.resolve(.macBookPro16), NotchLayout.resolve(.macBookPro16))
        XCTAssertEqual(NotchLayout.resolve(.studio), NotchLayout.resolve(.studio))
    }

    func testPlainDisplayKeepsACompactCenteredPill() {
        let screen = DisplayGeometry.studio
        let layout = NotchLayout.resolve(screen)
        XCTAssertEqual(layout.placement, .center)
        XCTAssertNil(layout.notchRect)
        XCTAssertEqual(layout.openSize.height, 24, accuracy: 0.01)
        XCTAssertEqual(layout.openSize.width, NotchMetrics.compactWidth, accuracy: 0.01)
        XCTAssertLessThan(layout.openSize.width, 280)
        XCTAssertLessThanOrEqual(layout.openSize.height, 36)
        XCTAssertEqual(layout.panelFrame.midX, screen.frame.midX, accuracy: 0.6)
        XCTAssertEqual(layout.panelFrame.maxY, screen.frame.maxY, accuracy: 0.01)
        XCTAssertEqual(layout.openOffset, 0, accuracy: 0.01)
        XCTAssertLessThan(layout.iconFrame.maxX, layout.textFrame.minX)
        XCTAssertEqual(layout.iconFrame.midY, layout.textFrame.midY, accuracy: 0.6)
        assertInsidePanel(layout)
    }

    func testABottomDockDoesNotStretchThePill() {
        var screen = DisplayGeometry.studio
        screen.visibleFrame = CGRect(x: 0, y: 70, width: 2560, height: 1440 - 24 - 70)
        let layout = NotchLayout.resolve(screen)
        XCTAssertEqual(layout.placement, .center)
        XCTAssertEqual(layout.openSize.height, 24, accuracy: 0.01)
    }

    func testPlainHeightFollowsTheMenuBar() {
        var screen = DisplayGeometry.studio
        screen.visibleFrame.size.height = screen.frame.height - 30
        let layout = NotchLayout.resolve(screen)
        XCTAssertEqual(layout.placement, .center)
        XCTAssertEqual(layout.openSize.height, 30, accuracy: 0.01)
    }

    func testExternalDisplayIsCenteredOnThatPanel() {
        let screen = DisplayGeometry.external
        let layout = NotchLayout.resolve(screen)
        XCTAssertEqual(layout.placement, .center)
        XCTAssertNil(layout.notchRect)
        XCTAssertEqual(layout.panelFrame.midX, screen.frame.midX, accuracy: 0.6)
        XCTAssertEqual(layout.panelFrame.maxY, screen.frame.maxY, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(layout.panelFrame.minX, screen.frame.minX)
        XCTAssertLessThanOrEqual(layout.panelFrame.maxX, screen.frame.maxX)
    }

    func testNotchOnAShiftedDisplayStaysWithThatDisplay() throws {
        let screen = shifted(.macBookPro14, dx: -1512, dy: 200)
        let layout = NotchLayout.resolve(screen)
        let notch = try XCTUnwrap(layout.notchRect)
        XCTAssertEqual(notch.minX, -1512 + 664, accuracy: 0.01)
        XCTAssertEqual(notch.maxY, screen.frame.maxY, accuracy: 0.01)
        guard case .flank = layout.placement else { return XCTFail("expected flank") }
        assertMissesHousing(layout, notch)
        XCTAssertGreaterThanOrEqual(layout.panelFrame.minX, screen.frame.minX - 0.6)
        XCTAssertLessThanOrEqual(layout.panelFrame.maxX, screen.frame.maxX + 0.6)
        XCTAssertEqual(layout.panelFrame.maxY, screen.frame.maxY, accuracy: 0.01)
    }

    func testNarrowLobesDropThePillBelowTheHousing() throws {
        let screen = DisplayGeometry(
            frame: CGRect(x: 0, y: 0, width: 280, height: 400),
            visibleFrame: CGRect(x: 0, y: 0, width: 280, height: 368),
            safeAreaTop: 32,
            auxiliaryTopLeft: CGRect(x: 0, y: 368, width: 40, height: 32),
            auxiliaryTopRight: CGRect(x: 240, y: 368, width: 40, height: 32),
            isMain: true)
        let notch = try XCTUnwrap(screen.notchRect)
        let layout = NotchLayout.resolve(screen)
        guard case .below(let clearance) = layout.placement else { return XCTFail("expected to drop below") }
        XCTAssertEqual(clearance, notch.height, accuracy: 0.01)
        XCTAssertLessThanOrEqual(layout.openSize.height, 36)
        assertFullyBelow(layout, notch)
        assertInsidePanel(layout)
    }

    func testShortHousingDropsBelowInsteadOfCrushingTheRow() throws {
        var screen = DisplayGeometry.macBookPro14
        screen.safeAreaTop = 12
        let layout = NotchLayout.resolve(screen)
        guard case .below(let clearance) = layout.placement else { return XCTFail("expected to drop below") }
        XCTAssertEqual(clearance, 12, accuracy: 0.01)
        assertFullyBelow(layout, try XCTUnwrap(layout.notchRect))
    }

    func testInsetWithoutAuxiliaryAreasDropsBelowTheObscuredBand() {
        var screen = DisplayGeometry.studio
        screen.safeAreaTop = 30
        screen.auxiliaryTopLeft = CGRect.zero
        screen.auxiliaryTopRight = CGRect.null
        XCTAssertNil(screen.notchRect)
        let layout = NotchLayout.resolve(screen)
        guard case .below(let clearance) = layout.placement else { return XCTFail("expected to drop below") }
        XCTAssertEqual(clearance, 30, accuracy: 0.01)
        XCTAssertNil(layout.notchRect)
        let band = CGRect(x: screen.frame.minX, y: screen.frame.maxY - 30, width: screen.frame.width, height: 30)
        assertFullyBelow(layout, band)
    }

    func testAreasThatAreNotOnTheTopEdgeAreNotANotch() {
        var screen = DisplayGeometry.studio
        screen.safeAreaTop = 28
        screen.auxiliaryTopLeft = CGRect(x: 0, y: 100, width: 400, height: 28)
        screen.auxiliaryTopRight = CGRect(x: 800, y: 100, width: 400, height: 28)
        XCTAssertNil(screen.notchRect)
        let layout = NotchLayout.resolve(screen)
        guard case .below(let clearance) = layout.placement else { return XCTFail("expected to drop below") }
        XCTAssertEqual(clearance, 28, accuracy: 0.01)
    }

    func testUsableAreaRejectsZeroNullAndInfinite() {
        XCTAssertNil(DisplayGeometry.usableArea(nil))
        XCTAssertNil(DisplayGeometry.usableArea(CGRect.zero))
        XCTAssertNil(DisplayGeometry.usableArea(CGRect.null))
        XCTAssertNil(DisplayGeometry.usableArea(CGRect.infinite))
        XCTAssertNotNil(DisplayGeometry.usableArea(CGRect(x: 0, y: 0, width: 10, height: 10)))
    }

    func testSelectFollowsThePointerThenTheMainDisplay() throws {
        var laptop = DisplayGeometry.macBookPro14
        laptop.isMain = false
        var panel = DisplayGeometry.external
        panel.isMain = true
        let screens = [laptop, panel]

        let onPanel = try XCTUnwrap(NotchLayout.select(screens, cursor: CGPoint(x: 2000, y: 100)))
        XCTAssertEqual(onPanel.frame, panel.frame)
        XCTAssertEqual(NotchLayout.resolve(onPanel).placement, .center)

        let onLaptop = try XCTUnwrap(NotchLayout.select(screens, cursor: CGPoint(x: 10, y: 900)))
        XCTAssertEqual(onLaptop.frame, laptop.frame)
        guard case .flank = NotchLayout.resolve(onLaptop).placement else { return XCTFail("laptop flanks") }

        XCTAssertEqual(try XCTUnwrap(NotchLayout.select(screens, cursor: nil)).frame, panel.frame)
        XCTAssertEqual(try XCTUnwrap(NotchLayout.select(screens, cursor: CGPoint(x: -5000, y: 0))).frame, panel.frame)
        XCTAssertNil(NotchLayout.select([], cursor: CGPoint(x: 0, y: 0)))

        let topEdge = try XCTUnwrap(NotchLayout.select([laptop], cursor: CGPoint(x: 100, y: laptop.frame.maxY)))
        XCTAssertEqual(topEdge.frame, laptop.frame)
    }

    private func shifted(_ base: DisplayGeometry, dx: CGFloat, _ dy: CGFloat) -> DisplayGeometry {
        var screen = base
        screen.frame.origin.x += dx
        screen.frame.origin.y += dy
        screen.visibleFrame.origin.x += dx
        screen.visibleFrame.origin.y += dy
        screen.auxiliaryTopLeft = screen.auxiliaryTopLeft?.offsetBy(dx: dx, dy: dy)
        screen.auxiliaryTopRight = screen.auxiliaryTopRight?.offsetBy(dx: dx, dy: dy)
        return screen
    }

    private func assertMissesHousing(_ layout: NotchBannerLayout, _ housing: CGRect, file: StaticString = #file, line: UInt = #line) {
        for local in [layout.iconFrame, layout.textFrame] {
            let frame = layout.globalFrame(local)
            let hit = frame.intersection(housing)
            XCTAssertTrue(hit.isNull || hit.width < 0.6 || hit.height < 0.6,
                          "content \(frame) intersects the housing \(housing)", file: file, line: line)
        }
    }

    private func assertFullyBelow(_ layout: NotchBannerLayout, _ housing: CGRect, file: StaticString = #file, line: UInt = #line) {
        assertMissesHousing(layout, housing, file: file, line: line)
        for local in [layout.iconFrame, layout.textFrame] {
            let frame = layout.globalFrame(local)
            XCTAssertLessThanOrEqual(frame.maxY, housing.minY + 0.6,
                                     "content top \(frame.maxY) is still inside the housing bottom \(housing.minY)",
                                     file: file, line: line)
        }
        let pillTop = layout.panelFrame.maxY - layout.openOffset
        XCTAssertLessThanOrEqual(pillTop, housing.minY + 0.6, file: file, line: line)
    }

    private func assertInLobes(_ layout: NotchBannerLayout, _ screen: DisplayGeometry, _ notch: CGRect, file: StaticString = #file, line: UInt = #line) {
        let icon = layout.globalFrame(layout.iconFrame)
        let text = layout.globalFrame(layout.textFrame)
        XCTAssertTrue(screen.auxiliaryTopLeft?.contains(CGPoint(x: icon.midX, y: icon.midY)) == true, file: file, line: line)
        XCTAssertTrue(screen.auxiliaryTopRight?.contains(CGPoint(x: text.midX, y: text.midY)) == true, file: file, line: line)
        XCTAssertLessThanOrEqual(icon.maxX, notch.minX - 4, file: file, line: line)
        XCTAssertGreaterThanOrEqual(text.minX, notch.maxX + 4, file: file, line: line)
    }

    private func assertInsidePanel(_ layout: NotchBannerLayout, file: StaticString = #file, line: UInt = #line) {
        for local in [layout.iconFrame, layout.textFrame] {
            XCTAssertGreaterThanOrEqual(local.minX, -0.1, file: file, line: line)
            XCTAssertGreaterThanOrEqual(local.minY, -0.1, file: file, line: line)
            XCTAssertLessThanOrEqual(local.maxX, layout.panelFrame.width + 0.1, file: file, line: line)
            XCTAssertLessThanOrEqual(local.maxY, layout.panelFrame.height + 0.1, file: file, line: line)
            XCTAssertGreaterThan(local.width, 8, file: file, line: line)
            XCTAssertGreaterThan(local.height, 8, file: file, line: line)
        }
    }

    private func assertRoundTrip(_ layout: NotchBannerLayout, file: StaticString = #file, line: UInt = #line) {
        for local in [layout.iconFrame, layout.textFrame] {
            let back = layout.panelLocal(layout.globalFrame(local))
            XCTAssertEqual(back.minX, local.minX, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(back.minY, local.minY, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(back.width, local.width, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(back.height, local.height, accuracy: 0.01, file: file, line: line)
        }
    }
}
