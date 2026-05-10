# VectorToonz for iPad

VectorToonz is a SwiftUI iPad prototype for a touch-first, vector-only animation workflow inspired by OpenToonz.

## Scope

Included:

- SwiftUI iPad app target in `VectorToonz.xcodeproj`
- vector-only document model with layers, frames, palette styles, and strokes
- touch-friendly editor layout with canvas, floating tool palette, vector layer stack, timeline, and inspector
- gesture navigation for pinch zoom, pan, and canvas rotation
- Apple Pencil/touch stroke capture as vector point data
- local JSON autosave
- Linux-testable Swift package for the platform-neutral vector document core

Intentionally excluded:

- raster brushes
- raster levels
- cleanup/scanning workflows
- rigging, skeleton, and plastic tools
- desktop Qt panel parity

## Open in Xcode

1. Open `/home/runner/work/opentoonz/opentoonz/ios/VectorToonz/VectorToonz.xcodeproj`.
2. Select the `VectorToonz` scheme.
3. Run on an iPad simulator or iPad device with iOS 17 or newer.

## Validate the core model

From this directory:

```sh
swift test
```

The Swift package validates the vector-only animation document model independently from SwiftUI, which requires Apple SDKs.
