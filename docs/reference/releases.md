# Release Naming

CalVer-style is used starting with the release in December 2024.

`YY.MINOR.PATCH` where:

- `YY`: short calendar year (24, 25, 26)
- `MINOR`: zero-padded release number in the calendar year (01, 02, 03) - that's what we'll call an actual release
- `PATCH`: patch number for a specific release (1, 2, 3) - just some bug fixes for a release

First release of the 2025 is 25.01 and patch releases for it named 25.01.1, 25.01.2, etc (if needed).
Last release of the 2024 is 24.09, it was originally named B2 (Beta 2).

API backward compatibility and in-place upgrades are guaranteed starting with the B1 release (Oct 24 2024).
Some new features may require manual intervention or installation from scratch to get them enabled, in this case, it
will be explicitly mentioned in the release notes.
