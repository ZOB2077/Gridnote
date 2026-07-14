# Contributing To Gridnote

Thank you for improving Gridnote. Contributions are reviewed for product fit, privacy impact, maintenance cost, and compatibility with the source-available license.

## Before You Start

- Read [PRODUCT_SPEC.md](PRODUCT_SPEC.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [AGENTS.md](AGENTS.md).
- Search existing issues and pull requests before opening a new one.
- Discuss substantial features in an issue before implementation. Keep pull requests narrowly scoped.
- Do not add networking, analytics, DRM handling, private APIs, or office-suite trademark assets.
- Use synthetic fixtures only. Never commit real business data, private books, customer records, or screenshots containing them.

## Development Setup

1. Fork and clone the repository.
2. Run `git config core.hooksPath .githooks` to enable the repository privacy check before every commit.
3. Open `Gridnote.xcodeproj` in Xcode 27 beta.
4. Select the `Gridnote` scheme and run it on macOS.
5. Run the unit-test command from the README before submitting a pull request.

## Pull Request Expectations

- Describe the user-visible behavior and technical approach.
- Add or update unit tests for changed business logic.
- Keep parser, persistence, and UI responsibilities separate.
- Update documentation when behavior, shortcuts, support boundaries, or release status change.
- Do not include build products, DerivedData, local test fixtures containing private material, or unrelated formatting churn.

## Commit Style

Use concise imperative subjects, such as `Synchronize office and floating reader progress`. Prefer one logical change per commit when practical.

## Contributor License Grant

By submitting a contribution, you confirm that you have the right to submit it and agree to the contribution terms in [LICENSE](LICENSE), including the copyright holder's right to use and commercialize accepted contributions as part of Gridnote.

## Reporting Problems

Use the bug-report template for reproducible defects. Do not include book contents, personally identifiable information, or private source files in public issues. Security-sensitive reports must follow [SECURITY.md](SECURITY.md).
