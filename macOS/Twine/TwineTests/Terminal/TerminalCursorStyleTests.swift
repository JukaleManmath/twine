import AppKit
import Foundation
import SwiftTerm
import Testing

@testable import Twine

@MainActor
struct TerminalCursorStyleTests {
    @Test(arguments: [
        ("block", CoreTerminalConfig.CursorStyle.block),
        ("underline", CoreTerminalConfig.CursorStyle.underline),
        ("bar", CoreTerminalConfig.CursorStyle.bar),
    ])
    func cursorStyleDecodesFromJSON(value: String, expected: CoreTerminalConfig.CursorStyle) throws {
        let json = "{\"font_family\":\"\",\"font_size\":13,\"cursor_style\":\"\(value)\",\"colors\":{}}"
        let config = try JSONDecoder().decode(CoreTerminalConfig.self, from: Data(json.utf8))
        #expect(config.cursorStyle == expected)
    }

    @Test func applyCursorStyleSetsTheTerminalCursorShape() {
        let terminal = MetalTerminalView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        terminal.automaticallyFocuses = false
        terminal.applyCursorStyle(.block)
        #expect(terminal.getTerminal().options.cursorStyle == .steadyBlock)
        terminal.applyCursorStyle(.underline)
        #expect(terminal.getTerminal().options.cursorStyle == .steadyUnderline)
        terminal.applyCursorStyle(.bar)
        #expect(terminal.getTerminal().options.cursorStyle == .steadyBar)
    }

    @Test func applyCursorStyleDoesNotOverrideTerminalChangesWhenConfigIsUnchanged() {
        let terminal = MetalTerminalView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        terminal.automaticallyFocuses = false
        terminal.applyCursorStyle(.block)
        #expect(terminal.getTerminal().options.cursorStyle == .steadyBlock)
        // Simulate a terminal app (e.g. vim) changing the cursor via escape code
        terminal.getTerminal().setCursorStyle(.steadyBar)
        #expect(terminal.getTerminal().options.cursorStyle == .steadyBar)
        // SwiftUI re-renders with the same config style — must not override vim's cursor
        terminal.applyCursorStyle(.block)
        #expect(terminal.getTerminal().options.cursorStyle == .steadyBar)
    }

    @Test func clientResolvesCursorStyleFromTheCoreSnapshot() async throws {
        let transport = DelayedStartTransport(
            snapshot: .testReady(terminal: .init(fontFamily: "", fontSize: 13, cursorStyle: .bar))
        )
        let client = CoreClient(transport: transport)
        client.start()
        defer { Task { await client.stop() } }
        try await client.waitUntilRunning()
        #expect(client.terminalCursorStyle == .bar)
    }
}
