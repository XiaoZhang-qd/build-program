# IDTerm

A small sideload-friendly iOS terminal experiment.

- IPA: UIKit terminal UI.
- Shell: executes commands through the device /bin/sh -c.
- Dylib: reusable idterm_execute() shell bridge.
- Normal iOS sandbox restrictions remain in effect.

This intentionally does not include a sandbox-escape or jailbreak exploit. A normal IPA cannot legitimately become a system-root terminal just by bundling a dylib.

GitHub Actions builds arm64 IPA + dylib and publishes both to a GitHub Release.