# Known Limitations

- EPUB rendering extracts ordered text, metadata, and navigation. It does not reproduce full CSS layout, embedded fonts, scripts, media overlays, or complex tables.
- EPUB images are accepted in the archive fixture but are not shown in the canonical text reader.
- PDF is not supported. Convert PDF content to TXT or EPUB before importing.
- The office workspace is a visual disguise with plain-text cells. It has no formulas, XLSX import/export, macros, charts, sorting engine, or spreadsheet compatibility promise.
- The shortcut is active only while Gridnote is focused. There is no system-wide hotkey.
- Large TXT files are decoded in memory before being split into approximately 4KB blocks. The 20MB fixture meets the performance target, but substantially larger files may increase memory use.
- Security-scoped bookmarks are stored during import. A signed sandbox distribution still needs a dedicated end-to-end entitlement and bookmark-access audit.
- Window position and multi-display restoration are not finalized.
- Alias editing operates on the currently active book; bulk alias management is not available.
- DRM-protected EPUB content is unsupported. Gridnote does not remove or bypass DRM.
- There is no networking, cloud sync, online catalog, account system, telemetry, or crash-report upload.
- Release signing, notarization, hardened runtime review, and installer packaging are outside this MVP repository milestone.
