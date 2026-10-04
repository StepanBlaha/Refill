# Contributing to Refill

Thanks for helping make Refill better.

## The easiest ways to help

- **Report a bug** with the [bug report form](https://github.com/StepanBlaha/Refill/issues/new?template=bug_report.yml).
- **Suggest a feature** with the [feature request form](https://github.com/StepanBlaha/Refill/issues/new?template=feature_request.yml).
- **Security issues:** see [SECURITY.md](SECURITY.md). Please don't report them in public issues.

## Code contributions

Refill is open source under the [MIT License](LICENSE). Pull requests are welcome. For anything bigger than a small fix, please **open an issue first**, so we can agree on the approach before you spend time on it. By opening a pull request, you agree that your contribution is licensed under the MIT License. If you publish your own fork as an app, give it a different name and icon, and don't reuse Drip (see [TRADEMARKS.md](TRADEMARKS.md)).

### Setup

- macOS 14 or later, Xcode, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
- Full app with widgets: `scripts/run-xcode.sh`
- SwiftPM build and tests: `swift build && swift test`
- Disk image: `scripts/package.sh`
- Website: `cd site && npm install && npm run dev` (served under `/Refill`)

### Guidelines

- Keep pull requests small and focused, and say what you tested.
- `swift test` must pass. Add tests for reset detection, parsing and integrations (`Tests/RefillTests`).
- Follow the existing style: SwiftUI + AppKit, the tokens in `Sources/Refill/Theme.swift`, and the voice in [branding/BRAND.md](branding/BRAND.md). Drip is short and a little cheeky. Public writing stays plain.
- Never commit provider tokens, `~/.config/refill` contents, or personal usage data. `Refill --render` draws sample accounts only.
- Refill must never imply it is made by Anthropic, OpenAI, GitHub, Cursor or Google. Keep the non-affiliation line wherever those names appear in marketing.
