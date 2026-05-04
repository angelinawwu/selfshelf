# SelfShelf

A tiny iOS 17+ SwiftUI app + WidgetKit extension that lets you curate book shelves from the [Open Library](https://openlibrary.org/developers/api) API and pin any shelf to your home screen as a small / medium / large widget.

## Requirements

- macOS with Xcode 15+ (iOS 17 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Generate the Xcode project

```sh
xcodegen generate
open SelfShelf.xcodeproj
```

The project is regenerated from `project.yml`. Don't hand-edit `SelfShelf.xcodeproj`.

## Run

1. Open `SelfShelf.xcodeproj`.
2. Pick the **SelfShelf** scheme, any iOS 17+ simulator (e.g. iPhone 15).
3. Build & run.
4. Long-press an empty area on the home screen → **Add Widget** → **SelfShelf** → pick a size. Long-press the widget → **Edit Widget** to pick which shelf it displays.

### Simulator notes

- Code signing is disabled in `project.yml` so the simulator build works out of the box. To run on a device, flip `CODE_SIGNING_ALLOWED` / `CODE_SIGNING_REQUIRED` back to `YES` and add your team.
- The app and widget share the App Group `group.com.selfshelf.shared`. Both targets include this entitlement.

## Architecture

- `SelfShelfKit/` — shared models (`Shelf`, `Book`, SwiftData), `OpenLibraryClient`, `CoverCache` (disk cache in the App Group container), design system, and the widget `AppIntent` (`SelectShelfIntent` + `ShelfEntity`).
- `SelfShelf/` — the app (Shelves, Search, Book detail, Shelf editor, Settings).
- `SelfShelfWidget/` — WidgetKit extension with small / medium / large layouts.

All three targets share the same SwiftData store (backed by `ModelContainer` on the App Group URL) and the same on-disk cover cache, so widgets render without hitting the network.

## Typography

- Headers: **Sentient Light** (`Sentient-Light.otf`)
- Body: **Archivo** light / regular / medium only — never bold
- Captions / labels: **PT Mono**, ALL CAPS, 70% opacity, letter-spaced

All three fonts are bundled in `SelfShelf/Resources/Fonts/` and registered via `UIAppFonts` on both targets.

## Deep links

Tapping a book cover in the widget opens `selfshelf://book/{olid}` which routes to the book's detail screen in the app.
