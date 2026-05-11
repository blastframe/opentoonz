# VectorToonz for iPad

VectorToonz is a SwiftUI iPad prototype for a touch-first, vector-only animation workflow inspired by OpenToonz.

## Scope

Included:

- SwiftUI iPad app target in `VectorToonz.xcodeproj`
- vector-only document model with layers, frames, palette styles, strokes, and OpenToonz-style vector tool operations
- touch-friendly editor layout with canvas, floating tool palette, vector layer stack, timeline, and inspector
- gesture navigation for pinch zoom, pan, and canvas rotation
- Apple Pencil/touch stroke capture as pressure-aware vector point data
- local JSON autosave
- Linux-testable Swift package for the platform-neutral vector document core

Intentionally excluded:

- raster brushes
- raster levels
- cleanup/scanning workflows
- raster paint brush and raster-only level editing
- desktop Qt panel parity

## Open in Xcode

1. From this directory, open `VectorToonz.xcodeproj`.
2. Select the `VectorToonz` scheme.
3. Run on an iPad simulator or iPad device with iOS 17 or newer.

## Validate the core model

From this directory:

```sh
swift test
```

The Swift package validates the vector-only animation document model independently from SwiftUI, which requires Apple SDKs.
