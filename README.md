# Nini — mobile-hywork

Flutter application maintained in the client's
[mobile-hywork repository](https://github.com/mojtaba-zarabi/mobile-hywork).
The Dart package name is `nini`, and the app UI is Persian (`fa_IR`).

## Current implementation

| Area | Implemented behavior |
| --- | --- |
| Client icons | 421 matching Coolicons SVGs plus 657 legacy PNG assets, with centralized paths and theme-aware rendering. Screenshot crops are retained only as references. |
| Themes | Light, Dark, and System modes; contrasting buttons, labels, icons, and loading spinners. |
| Gallery | Photo/video selection with `photo_manager`, native file picking, Android/iOS permissions, and preview grids. |
| Create post | Title, rich caption, pricing, stock, post type, preparation time, unit, schedule, address/map, features, tags, and alt text. |
| Publishing | Validation, loading/duplicate-submit protection, durable local media copies, saved posts, and navigation back to the Home feed. |
| Post details and analytics | Real published content, a **مشاهده آمار** entry point, five chart sections, and device-local activity tracking. |
| Chat | Searchable inbox, text/voice/photo/video/file messages, device-emoji picker, local message deletion, and block/unblock controls. |
| Call UI previews | Voice incoming/active screens and video screen with interactive controls; no calling backend. |
| Persian UI | Translated screens, sheets, errors, hints, tooltips, chart labels, and displayed numbers. |
| Code cleanup | Normalized names, separate domain models, typed post details, smaller form sections, configurable text direction, and individual chart files. |

Publishing and analytics currently use storage on the device. Server upload,
cross-device sync, scheduled background publication, and completed-order tracking
are not connected. The sections below describe the implemented behavior and
these integration boundaries.

## Run the app

Use a Flutter installation whose bundled Dart SDK satisfies `^3.13.3`, as declared
in [pubspec.yaml](pubspec.yaml). Gallery access should be checked on a configured
Android/iOS emulator or physical device.

For a fresh checkout:

```sh
git clone https://github.com/mojtaba-zarabi/mobile-hywork.git
cd mobile-hywork
flutter pub get
flutter run
```

From an existing checkout, run `flutter pub get` and `flutter run`. Native plugin
or permission changes require stopping and rebuilding the application; hot reload
alone does not install native changes.

## Client repository and Git workflow

The project has been published to the client's **main** branch:
[mobile-hywork/main](https://github.com/mojtaba-zarabi/mobile-hywork/tree/main).
The import preserved both repositories' existing commit histories and did not use
a force push. The earlier `zeeshan/nini-flutter-app` branch is an initial review
copy; `main` is the current client delivery branch.

In the existing development checkout:

| Item | Configuration |
| --- | --- |
| Local working branch | `main` |
| Upstream | `client/main` |
| Client remote | `client` → `https://github.com/mojtaba-zarabi/mobile-hywork.git` |
| Personal remote | `origin` remains the personal repository. |
| Original personal branch | Local `master` remains associated with `origin/master`. |

After reviewing and committing a future change on local `main`, `git push` sends
it to the client repository:

```sh
git status
git add README.md
git commit -m "Update project documentation"
git push
```

The example stages only `README.md`; stage the relevant source files when making
an application change. To state the destination explicitly, use
`git push client HEAD:main` from this checkout. A fresh clone of the client
repository names that repository `origin` automatically, so the `client` alias
is specific to the existing development checkout.

## Gallery packages and permissions

Installed `photo_manager: ^3.12.0` and
`photo_manager_image_provider: ^2.2.0` using:

```sh
flutter pub add photo_manager photo_manager_image_provider
```

Native setup follows the [photo_manager documentation](https://pub.dev/packages/photo_manager#configure-native-platforms):

- `android/app/src/main/AndroidManifest.xml`: `READ_EXTERNAL_STORAGE` through
  API 32, `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` for API 33+, and
  `READ_MEDIA_VISUAL_USER_SELECTED` for selected-media access on API 34+.
- `ios/Runner/Info.plist`: `NSPhotoLibraryUsageDescription` with a Persian
  explanation for selecting post photos/videos.

The create-post gallery requests permission for the active media tab:
`RequestType.image` for Photo and `RequestType.video` for Video, using matching
`AndroidPermission` options. This avoids blocking photos when Android video
permission is denied (and vice versa). Both queries use the All album and paging;
page continuation uses the album's total count so short pages do not hide later
media. A failed page retains a Retry action.

On iOS and Android 14+, limited permission exposes only the items the user has
approved. A Persian notice offers Select more and Full access in Settings.
The app cannot override that choice to show the entire library. `GalleryGrid`
refreshes permission and assets after returning from Settings, without another
permission prompt. Shared library-change notifications also reload changes to
limited selections and newly added media, including the iOS 14 picker whose
completion callback returns early. Refresh events during a query are queued.

The File tab opens the native document browser and displays the files selected
there. It does not enumerate every document on the phone. It needs no photo or
video permission, and app resume never reopens the document picker. Selection
persists when switching tabs or cancelling a later file selection.

`AssetEntityImage` / `AssetEntityImageProvider` display thumbnails. Native changes
require a full rebuild. Denial and initial-query failures have Settings/Retry
recovery; the create-post and compact chat galleries share the same behavior.

## Light and dark mode

The theme logic lives in `lib/core/theme/`:

| File | Responsibility |
| --- | --- |
| [`app_theme.dart`](lib/core/theme/app_theme.dart) | Builds `AppTheme.light` and `AppTheme.dark`: colors, typography, buttons, icons, menus, tooltips, app bars, and system bars. |
| [`theme_cubit.dart`](lib/core/theme/theme_cubit.dart) | Stores the current `ThemeMode` and exposes methods to change it. Uses the existing `flutter_bloc` dependency. |
| [`theme_mode_menu.dart`](lib/core/theme/theme_mode_menu.dart) | Sun/moon button in the home header with Light, Dark, and System choices. Labels are Persian, matching the app. |

### Color rules

| Element | Light mode | Dark mode |
| --- | --- | --- |
| Main backgrounds | White (`#FFFFFF`) | Black (`#000000`) |
| Surface text, including descriptions, prices, counts, and chip labels | Black (`#000000`) | White (`#FFFFFF`) |
| Client icons and built-in icons on page surfaces | Black | White |
| Primary elevated/filled button backgrounds | Black | White |
| Primary button labels, icons, and loading spinners | White | Black |
| Outlined/text/icon button labels and icons | Black | White |
| Outlined button backgrounds | White with gray border | Black with gray border |
| Placeholder and selected-chip surfaces | Light gray | Dark gray |
| Dividers and borders | Light gray | Gray |

Create-post option sheets intentionally use the **opposite palette** to the
page: a light app shows black sheets with white text/icons, and a dark app shows
white sheets with black text/icons. This applies to post type, preparation time,
unit, schedule, features, address, alt text, and tags. `showPostDialog` scopes
`AppTheme.dark` or `AppTheme.light` to the sheet in `post_dialog.dart`; the page
keeps its original theme. Shared buttons, fields, choice indicators, calendar,
and Cupertino time picker inherit that local palette. An open sheet follows
later app-theme changes while preserving its form values.

Sheet icons use `AppIcons` / `AppIcon`, including the tag add/remove controls,
address-map pin, and alt-text image fallback. No client icon artwork is changed.

Primary actions (Publish/Done) use `colorScheme.primary` for the fill and
`colorScheme.onPrimary` for their labels, icons, and loading spinners. Secondary
outlined actions (Cancel) use `surface` with `onSurface` text/icons and an
`outline` border. Elevated and filled buttons share the primary style with no
elevation and 6-pixel rounded corners. Disabled/loading controls retain these
contrast colors; loading still disables taps. `AppButton` in
`lib/shared/widgets/app_button/app_button.dart` inherits these shared themes, including
the Cancel/Publish pair on `CreatePostDetailsScreen`. Standalone icons and text
buttons continue to use black in light mode and white in dark mode. Client icons are
tinted **at runtime** using `BlendMode.srcIn`; only their opaque pixels change
color, and their shapes/transparency are preserved. SVG paths remain vector at render time; legacy PNG files stay unchanged.
Photos, existing red notification-badge backgrounds, and the author's green
avatar ring retain their colors. Badge text follows the black/white text rule.
Gallery indicators remain white over photos so their visibility does not depend
on the page background.

Selected navigation, heart, and bookmark icons use a subtle foreground-colored
background at 14% opacity. Their actual icon pixels stay black/white in both
selected and unselected states. The profile tab uses border thickness to show
selection; category chips use a filled surface and a stronger border. Existing
selection and like/bookmark accessibility states remain available.

### Mode selection and app wiring

The app starts with `ThemeMode.system`. It follows the device's brightness and
updates automatically when the OS switches between light and dark. The sun/moon
button in the home header lets users explicitly choose Light, Dark, or System.
An explicit choice overrides device brightness until System is selected again.

`MyApp` provides one `ThemeCubit` above `MaterialApp`. A `BlocBuilder` connects its
state to `MaterialApp.themeMode`, with `AppTheme.light` as `theme` and
`AppTheme.dark` as `darkTheme`. This placement applies the same theme to the home
screen, bottom navigation, dashboard tabs, menus, and pushed post-detail routes.
Switching modes updates those screens without resetting navigation or post state.
System status/navigation bar contrast is updated alongside the app theme.

The selected mode is stored **in memory for the current app session**. A full
restart returns to System; no persistent preference storage has been added.
`MyApp(initialThemeMode: ThemeMode.dark)` can set a different startup mode for a
preview/test. To update the app from a widget below `MyApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/theme/theme_cubit.dart';

context.read<ThemeCubit>().setThemeMode(ThemeMode.light);
context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);
context.read<ThemeCubit>().useSystemTheme();

// Toggle using the currently rendered brightness, including in System mode.
context.read<ThemeCubit>().toggleTheme(Theme.of(context).brightness);
```

### Rules for future screens

- Use `Scaffold` defaults or `Theme.of(context).colorScheme.surface` for page/card
  backgrounds.
- Let `Text`/`Icon` inherit their color. If a custom drawing needs an explicit
  foreground, use `Theme.of(context).colorScheme.onSurface`.
- Use `AppIcon` for client icons and leave `color` unset to inherit the current
  `IconTheme`. Use `selected: true` for a selected background highlight.
- Use `colorScheme.surfaceContainerHighest` for neutral placeholder surfaces and
  `Theme.of(context).dividerColor` / `colorScheme.outline` for borders.
- Use the standard button widgets so they inherit the centralized button themes.
- Avoid hardcoded black/white/gray foreground colors in feature widgets. Add
  shared theme decisions in `AppTheme` and keep Persian copy in `AppStrings`.
- Treat `ThemeCubit.state` as a preference: System is resolved by `MaterialApp`.
  Use `Theme.of(context).brightness` when you need the actual rendered mode.

[`test/theme_test.dart`](test/theme_test.dart) covers the controller, exact button
foregrounds, real theme-menu interaction, rendered text/SVG/PNG colors, system changes,
manual overrides, and changing theme on a pushed post without losing its state.

## Create-post details, dialogs, and caption editor

The editable form is
[`CreatePostDetailsScreen`](lib/features/create_post/presentation/pages/create_post_details_screen.dart).
It is the second step of the create-post flow, after gallery selection. It shares
one `CreatePostCubit` with the gallery; the existing published-post viewing screen
is a separate feature.

Each sheet is a separate reusable widget under
`lib/features/create_post/presentation/widgets/`:

| Folder/widget | Behavior |
| --- | --- |
| `post_dialog/` | Common rounded sheet, drag handle, right-aligned heading, selection rows, and shared Cancel/Done buttons. Handles keyboard insets, scrolling, and tablet width. |
| `post_type_dialog/TypePostDialog` | Product/Services single selection; commits on tapping a row. |
| `preparation_time_dialog/PreparationTimeDialog` | No preparation, same day, or 1/2/3/5/7/10/14/30 days. |
| `unit_dialog/UnitDialog` | Piece, Item, Hour, Day, Session, Project, Meter, Centimeter, Kilogram, Set. |
| `schedule_post_dialog/SchedulePostDialog` | Calendar and Time tabs with 24-hour wheels, From/To selection, future-time validation, and removal of an existing schedule. Earlier end times mean the next day; equal times are rejected. |
| `address_dialog/AddressDialog` | Interactive Flutter map above an overlapping address sheet. Tap a pin, enter an address, add/select saved addresses, and confirm. |
| `features_dialog/FeaturesDialog` | Add feature/value pairs, tap a row to edit, remove rows, reject empty/duplicate names, and confirm. |
| `alt_text_dialog/AltTextDialog` | Per-attachment descriptions and thumbnails; keyed by stable attachment ID. |
| `tags_dialog/TagsDialog` | Add comma-separated tags, normalize/deduplicate them, and remove chips. |
| `caption_editor/CaptionEditor` | Rich caption editing with bold, italic, underline, strike-through, lists, alignment, direction, links, indent, clear formatting, undo, and redo. Toolbar scrolls horizontally on smaller screens. |

The inventory selector also uses the shared choice-sheet widget. All option rows
open their sheet and show their saved value. Title, price, discount, and stock
remain editable with `AppTextField`. Confirmation buttons reuse `AppButton` and
inherit the contrasting primary/outlined themes. Save-based sheets edit a local
copy: Cancel, back, or dismiss leaves the draft unchanged. Simple choice sheets
commit immediately on selection.

### Draft data and caption formatting

`domain/models/post_options.dart` defines typed creation options and re-exports
the shared address, feature, and schedule models. `PostDraft` stores these alongside plain
caption text and a Quill `captionDelta`. The controller listens for document
changes and stores both representations. Reopening the details screen restores
the Delta, preserving formatting. Use the Delta for rich rendering; the plain
`caption` is for validation/search. Do not rebuild a formatted document from the
plain text. [`flutter_quill`](https://pub.dev/packages/flutter_quill) provides the
editor; its localization delegate is installed in the app and the reusable editor.
The editor owns/disposes its focus and scroll controllers.

`PostDraft.toJson()` supplies the complete snapshot used by local
publishing. Schedule dates are serialized as UTC ISO strings; the UI uses local
device time. The editable draft and saved address choices are in memory for the
create-post flow; a published post's snapshot is saved on disk. Selecting a
schedule stores metadata; it does not create an OS background task or server job.
Publish saves the post locally and makes it visible immediately. The extra Next
button was removed from the details screen; the gallery's Next still advances to
the form.

### Map behavior

[`flutter_map`](https://docs.fleaflet.dev/usage/basics) and `latlong2` provide map
interaction. Map tiles come from OpenStreetMap over HTTPS, with visible attribution
and an app user agent. `url_launcher` opens the attribution link. Release Android
now declares `INTERNET`; iOS uses HTTPS without an ATS exception. The map follows
the monochrome design with grayscale light tiles and inverted grayscale dark
tiles. Failed tile loads show a retry action.

The initial map view is Tehran, **not a detected user location**. The user taps
the map for coordinates and types the address; address search, reverse geocoding,
and GPS access are not implemented. No location permission is requested. Saved
addresses are only those the user adds during this flow. Network tile display
requires internet; pin/address data is saved privately with a locally published post. Map providers can be swapped via `LocationMap.tileProvider`.
Review the [OpenStreetMap tile policy](https://operations.osmfoundation.org/policies/tiles/)
when choosing the production tile service.

`test/create_post_options_test.dart` verifies typed draft serialization, selections
in both themes, feature validation/edit/remove, schedule validation and midnight
ranges, address selection with offline test tiles, cancellation, alt text/tags,
caption formatting, and wiring back into the details form.

## Publishing and the shared post feed

Publish validates the form, shows the existing `AppButton` loading spinner, and
disables duplicate submissions, editing, and back/cancel while the save is in
progress. Failure keeps the draft and selected attachments intact, shows an
error, and re-enables Publish. Success returns a typed `PostItem` through details
→ gallery → dashboard, switches to Home, and scrolls to the new first post.

| Component | Responsibility |
| --- | --- |
| `features/posts/domain/posts_repository.dart` | Storage interface, separate from screens and navigation. |
| `features/posts/data/local_posts_repository.dart` | Copies gallery/picked media to private app storage, writes the post snapshot, and reloads published posts. |
| `features/posts/presentation/cubit/posts_cubit.dart` | One shared feed above `MaterialApp`, plus load/publish state and duplicate-save protection. |
| `features/posts/data/demo_posts.dart` | Existing sample posts, kept separate from user-created posts. |
| `shared/models/post/post_item.dart` and `post_media.dart` | Post identity, media, compatibility accessors, and JSON serialization. |
| `shared/models/post/post_details.dart` and `post_attributes.dart` | Typed caption, tags, address, schedule, features, stock/discount details, and legacy metadata compatibility. |
| `shared/widgets/post_media/post_media_view.dart` | Displays app-owned image files, video thumbnails when available, and named file/video placeholders. |
| `features/posts/presentation/widgets/published_post_content.dart` | Read-only rich caption, actual title/price/tags/address, and saved schedule metadata. |

Published posts and media are stored under `nini_posts/` in the application
Documents directory (`path_provider` on other platforms; the iOS sandbox directly
on iOS, so an already-running app does not depend on new FFI assets to save). Media paths in `posts.json` are relative
so they survive changes to the app's Documents path. Selected original files are
copied, so temporary picker paths and later gallery permission changes do not
remove the published copy. Metadata is replaced atomically after copying media;
a failed save does not add a half-finished post. If a gallery preview-file export
fails, publishing tries the original image export before reporting failure. A damaged existing index is not
overwritten. The Home feed shows a retry action if saved posts fail to load.

New posts appear before the samples and open in the existing post viewer, which
uses their own media carousel, rich caption, feature rows, and alt text. New post
engagement starts at zero and has no fabricated sample rating. Optional empty
prices are hidden; discount percentages and stock are validated, including
Persian/Arabic numerals. Videos retain their original file and optional gallery
thumbnail; playback/document-opening controls are not implemented here.

This is **publishing on this device**, with persistence across restarts. There is
no account/server upload or cross-device sync. A future remote implementation can
replace `PostsRepository` without putting networking into the UI. Do not report a
server upload or scheduled background publication from the local save result.

`test/publish_post_test.dart` verifies real media copying and reload, preservation
of older posts, failure cleanup, input validation, duplicate submits during startup
loading, spinner/disabled controls, recovery after failure, both route pops, Home
updates, and opening the real rich post content in both themes. Other UI tests
inject an empty repository to avoid depending on native storage in widget tests.

## Client icons

The original 13 supplied PNG sheets are preserved, unchanged, in
[`assets/icons/source_sheets/`](assets/icons/source_sheets/). The collection contains
**657 individual transparent PNG icons**, grouped under `assets/icons/`:

| Folder | Original sheet | Icons |
| --- | --- | ---: |
| `arrows/` | Frame 10.png | 70 |
| `general/` | Frame 11.png | 126 |
| `finance/` | Frame 12.png | 64 |
| `media/` | Frame 13.png | 68 |
| `alerts/` | Frame 14.png | 17 |
| `images/` | Frame 16.png | 22 |
| `files/` | Frame 17.png | 53 |
| `weather/` | Frame 18.png | 30 |
| `travel_location/` | Frame 19.png | 34 |
| `charts/` | Frame 20.png | 38 |
| `development/` | Frame 25.png | 40 |
| `editor/` | Frame 28.png | 78 |
| `education/` | Frame 29.png | 17 |

The individual files are exact RGBA crops of the supplied artwork, including its
original colors, antialiasing, and transparency. No icons were redrawn, traced,
recolored on disk, or enlarged on disk. Each crop is 26 × 26 pixels, covering the
nominal 24-pixel icon slot with a small margin to preserve edge pixels. Sheet
headings and text labels are excluded.

Filenames follow the sheet labels, with spaces/case normalized and `attachment`
spelled consistently. Repeated labels receive `-variant-2` (and so on) so distinct
drawings are kept. [`tool/client_icons.json`](tool/client_icons.json) records every
asset path, original sheet label, column, row, and exact crop rectangle.

The original 13 PNG folders and 13 vector category folders are registered in [`pubspec.yaml`](pubspec.yaml).
Original sheets and the extraction manifest are kept for reference and are not
bundled into the app.

### Supplemental screenshot icons (30 October 2026)

The 13 new category screenshots are preserved under
`assets/icons/supplemental/source_sheets/`. Their **421 icons** live in separate
category folders under `assets/icons/supplemental/` as reference crops. They are
**not bundled or used by the app**: these small bitmaps become pixelated when
scaled, including at normal logical sizes on high-density phone displays.

All 421 labels now map to original **Coolicons v4.1 SVGs** by Kryston Schwarze,
copied unchanged into `assets/icons/vectors/<category>/`. These are real SVG paths,
not embedded PNGs or automatically traced screenshots. `AppIcon` renders them
using `flutter_svg` with its default vector picture rendering strategy. Theme
tints, button actions, accessibility labels, and selection styles are preserved.
The bundled collection contains **421 SVGs and 657 legacy PNGs**.

Source: [Coolicons v4.1](https://github.com/krystonschwarze/coolicons/tree/v4.1),
commit `42d70477683a0c44cd1732b32a9def8a94469c5a`. This release uses
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); attribution is retained
in [`assets/icons/vectors/NOTICE.md`](assets/icons/vectors/NOTICE.md).
`tool/supplemental_vectors.json` records every mapping, upstream filename, commit,
and SHA-256 checksum. Reimport from the pinned checkout with:

```sh
git clone --depth 1 --branch v4.1 https://github.com/krystonschwarze/coolicons.git /tmp/coolicons-v4.1
python3 tool/import_supplemental_vectors.py /tmp/coolicons-v4.1
```

The importer handles five spelling differences in upstream filenames while
retaining readable app filenames. It validates the complete mapping before
writing assets. The category counts below apply to both the reference crops and
the matching runtime SVGs.

| Category | Icons |
| --- | ---: |
| arrows | 72 |
| files | 39 |
| interface | 73 |
| calendar | 14 |
| navigation | 18 |
| edit | 72 |
| communication | 27 |
| environment | 13 |
| media | 22 |
| system | 36 |
| user | 13 |
| shape | 6 |
| menu | 16 |

These screenshots have a baked-in dark background. The extraction removes that
background and recovers white-foreground alpha; it preserves the native pixel
grid, outline, antialiasing, and proportions. No drawing, tracing, or upscaling is
performed. The crops are 28–34 pixels square with transparent margins. Repainting
a crop over its recorded source background differs by at most two RGB levels
from the screenshot due to alpha quantization. Labels and category headings are
excluded, including clipped text beside otherwise complete icons.

`tool/supplemental_icons.json` records each source, label, category row/column,
crop rectangle, background color, and reconstruction error. Recreate the assets
with Pillow installed:

```sh
python3 tool/extract_supplemental_icons.py
```

Only the 13 **vector** leaf folders are registered in `pubspec.yaml`; supplemental
PNG crops, source sheets, and extraction metadata are excluded from the app bundle. Fully restart/rebuild
the app after adding the new asset folders.

The call controls now use client handset/chat assets and retain their callbacks,
selected/disabled states, and contrasting colors. The hang-up button rotates the
same handset at render time. The caption toolbar uses client bold, italic,
underline, strikethrough, undo, and redo artwork through Quill's existing action
callbacks. Other editor formatting controls and stored Delta data are unchanged.

## How icons are used

[`AppIcons`](lib/core/icons/app_icons.dart) holds the paths currently used by the
app. [`AppIcon`](lib/shared/widgets/app_icons/app_icon.dart) displays an asset with its
transparency and aspect ratio preserved. SVGs use `SvgPicture.asset`; legacy PNGs
use `Image.asset`. Do not convert screenshots to SVG wrappers: embedded bitmaps
still pixelate.

```dart
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

// Inherits black in light mode and white in dark mode.
const AppIcon(AppIcons.search, size: 28);

// Give an interactive control its existing label and callback.
IconButton(
  tooltip: AppStrings.search,
  onPressed: onSearch,
  icon: const AppIcon(AppIcons.search, size: 28),
);

// For a meaningful standalone image, supply an accessibility label.
const AppIcon(AppIcons.cart, size: 28, semanticLabel: AppStrings.cart);
```

The example uses the shared Persian labels from `AppStrings`. Existing controls
retain their callbacks, counts, and layout sizes.

| App location/action | Client asset (relative to `assets/icons/`) |
| --- | --- |
| Bottom navigation: home | `vectors/navigation/house-01.svg` |
| Bottom navigation: cart | `vectors/interface/shopping-cart-01.svg` |
| Create tab and add category | `vectors/edit/add-plus.svg` |
| Search tab | `vectors/interface/search-magnifying-glass.svg` |
| Profile/avatar fallback | `vectors/user/user-circle.svg` |
| Home header: theme menu | `vectors/environment/sun.svg` / `moon.svg` |
| Home header: messages and post comments | `vectors/communication/chat.svg` |
| Menus and close | `vectors/menu/more-vertical.svg` / `close-md.svg` |
| Back and refresh | `vectors/arrows/chevron-left-md.svg` / `arrows-reload-01.svg` |
| Bookmark, heart, star, tag, trash | Matching `vectors/interface/` assets |
| Call handset and chat send | `vectors/communication/phone.svg` / `paper-plane.svg` |
| Gallery image/play/pause/volume | Matching `vectors/media/` assets |
| Location and map | `vectors/navigation/map-pin.svg` / `map.svg` |
| File, calendar, preparation time | `vectors/files/file-document.svg`, `calendar/calendar.svg`, `calendar/clock.svg` |
| Camera and keyboard | `vectors/system/camera.svg` / `keyboard.svg` |
| Attachment and rich caption formatting | Matching `vectors/edit/` assets |
| Unavailable image, microphone, video camera | Original `images/` and `media/` assets, complementing the new collection |

`AppIcon` inherits the current `IconTheme` color, falling back to
`colorScheme.onSurface`: black in light mode and white in dark mode. Its optional
`color` argument is an explicit override; normal app controls leave it unset.
Use `selected: true` to add a subtle background highlight while keeping the same
foreground. Like/bookmark toggles also expose their state to accessibility services.
The supplemental collection now supplies the rating star and plain comment
bubble. Controls without an equivalent in these screenshots retain a suitable
original client asset or framework control, including native calendar/editor
controls and the emoji glyph. Six active original icons still use PNGs:
`imageUnavailable`, `target`, `microphone`, `microphoneOff`, `video`, and `videoOff`.
Their artwork is absent from the supplied Coolicons screenshots. Matching original
SVG exports are needed to make those six scalable without changing their design;
enlarging PNGs or renaming their extension does not restore vector quality.

## How to add another icon

1. Export the original **SVG** from the design file and put it in a vector category
   folder, for example `assets/icons/vectors/interface/new-icon.svg`. Keep genuine
   vector paths and a valid `viewBox`. Do not crop screenshots for new UI icons.
   PNG support remains for legacy artwork only.
2. Existing category folders are already registered. If adding a new category,
   add its directory under `flutter: assets:` in `pubspec.yaml`; Flutter does not
   recursively include arbitrary subdirectories from the existing `assets/` entry.
3. Add a descriptive constant in `lib/core/icons/app_icons.dart`:

   ```dart
   static const newIcon = 'assets/icons/vectors/interface/new-icon.svg';
   ```

4. Use `const AppIcon(AppIcons.newIcon, size: 24)` at the relevant control. Keep
   the control's tooltip, accessibility label, and existing callback. Leave
   `color` unset so the icon follows light/dark mode automatically.
5. Run `flutter pub get` and fully restart the app after changing asset entries.

Icons already in this collection can be used immediately by adding an `AppIcons`
constant for their existing path. SVG rendering uses the `flutter_svg` dependency;
an icon font is not required.

## Re-extract or verify the original collection

Pillow is needed only for this optional developer script, not for Flutter:

```sh
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install Pillow
python3 tool/extract_client_icons.py
python3 tool/extract_client_icons.py --check
```

The script reads `tool/client_icons.json` and the preserved source sheets. It
recreates the listed crops; `--check` verifies their dimensions, RGBA format, and
every pixel without writing files. Additional standalone icons need no manifest
entry. To extract a new sheet, preserve it under `source_sheets/` and add manifest
entries with `asset`, `source`, `label`, one-based `column`/`row`, and
`rect: [left, top, width, height]`. Each rectangle must contain only its icon.

```sh
flutter analyze
flutter test
```

## Post analytics

Open any post, then tap **مشاهده آمار** (View analytics) in the post-detail app bar. Back returns
with that post's current like/bookmark state preserved. The analytics header uses
the selected post's own image, and the screen follows the shared light/dark theme.
Purple, gold, pink, and blue identify chart series in both themes.

The feature keeps domain models separate from presentation Cubits and widgets:

```text
lib/features/post_analytics/
  data/post_analytics_repository.dart
  domain/models/post_analytics.dart
  presentation/
    cubit/post_analytics_cubit.dart
    pages/post_analytics_screen.dart
    widgets/
      activity_tracking/       # Post view, watch-time and home impression tracking
      analytics_header/        # Owner, location and selected post image
      analytics_controls/      # Period menus, tooltips, legends and summaries
      analytics_chart/         # Native CustomPainter chart rendering
      total_views/             # Overlapping smooth filled area charts
      clicks_interactions/     # Solid purple and dashed gold lines
      average_time_viewed/     # Overlapping radar plots
      impressions/             # Four-color polar area chart
      orders_bookings/         # Rounded blue seven-day bar chart
```

Each of the first four sections has an independent period selector (1, 3, 6,
or 12 calendar months, including the current month). Tap/drag line charts to
inspect a point. The line/radar legends toggle individual series. Tap the radar
to inspect another month, the impressions plot to toggle its tooltip, and an
orders bar to inspect that day. Charts are drawn as Flutter widgets and paths,
rather than a flattened screenshot; no chart service or chart image is required.

### What the numbers mean

- Existing sample posts display **داده‌های نمونه** (Sample data), with the reference design's
  illustrative product series, currency callouts, and `۸ ساعت` example.
- Published posts display **در این دستگاه** (On this device). They use recorded local events,
  without the sample currency totals. The view total counts post-detail openings.
  A home impression is recorded when at least 50% of a published post's card
  becomes visible. Scrolling below 10% and back into view can count another
  impression; these are exposures, not unique people.
- Positive like and bookmark actions count as interactions. The model also
  supports `share` and `comment` sources for future integrations; those actions
  currently require callbacks in the existing post-detail UI.
- Viewing time counts time spent on post details. It pauses while another route
  covers the post or the app is backgrounded. Segments share a session ID, so
  a pause/resume does not incorrectly create another viewing session. Monthly
  averages and the overall average are calculated from recorded sessions.
- Orders/bookings show actual counts and their seven-day daily average for a
  published post. They remain zero because no completed-order/booking flow is
  connected yet. The pale bar backgrounds are chart tracks, not orders.

These are device-local statistics, not cross-user/server analytics. `MyApp`
provides one `PostAnalyticsCubit`; events are saved atomically to
`post_analytics.json` in application Documents and restored after restart.
Writes are serialized to preserve concurrent actions. An unreadable history is
preserved, with a small status message; new events then remain in memory.

To connect real server analytics, implement `PostAnalyticsRepository` and inject
it through `MyApp(analyticsRepository: ...)`. A completed booking integration can
record `AnalyticsEventType.order` for the relevant post; the event's value is
its count, not its price. Keep revenue and order counts separate. Tests/previews
can inject `MemoryPostAnalyticsRepository` without native storage.

`visibility_detector` supplies the card visibility callbacks. Widget tests set
its interval to zero in `test/flutter_test_config.dart` to avoid pending timers.
Run `flutter test test/post_analytics_test.dart` for persistence, aggregation,
period/legend controls, navigation, and light/dark narrow-screen coverage.

## Persian text on the new screens

Gallery selection, the create-post form, its option dialogs, publishing messages,
post analytics, chat, call previews, and attachment sheets use Persian copy from
`lib/core/localization/app_strings.dart`.
This includes buttons, hints, validation errors, tooltips, chart legends, period
menus, month/weekday labels, and numeric summaries. Add future UI labels there
and reference `AppStrings` in widgets instead of hard-coding English text.
Bundled contact names, inbox previews, and demo conversation messages are Persian
as well. Chat search uses right-to-left input. Attachment sizes use Persian
kilobyte/megabyte labels, and file badges show Persian type names while preserving
original filenames and extensions. The map attribution is displayed in Persian
and retains its OpenStreetMap credit link.

The app locale remains `fa_IR`. Material date/time controls use its localized
labels. The caption editor explicitly loads Persian Quill/Flutter localization;
Undo/Redo have Persian tooltip overrides because the installed Quill Persian
translations leave those two labels in English. Input text reads right to left.
Create-post headings, form labels, hints, input text, and selected option values
align to the right. `AppTextField` scopes `Directionality` to its configured
text direction so floating labels follow RTL too; explicit LTR fields remain
supported. Option labels and values are grouped on the right, while caption
paragraphs start RTL and still respect explicit rich-text alignment choices.
Page navigation, photo order and chart timelines keep the existing layout.

Numbers in analytics are formatted with `AppStrings.persianDigits` for display.
Chart month names are Persian names of Gregorian months; this change does not
switch the stored calendar to Jalali. IDs, enum names, dates, JSON keys, event
values and user-entered content retain their original values. Previously saved
English Product/Services categories also display their Persian labels on home
cards without rewriting saved records.

## Code organization and behavior-preserving cleanup

```text
lib/
  main.dart                          # Existing startup and application wiring
  core/                              # Theme, strings, icons, responsiveness, animation
  shared/
    models/post/                     # PostItem, PostMedia, PostDetails, typed attributes
    widgets/                         # Buttons, icons, loader, fields, toasts, media views
  features/
    calls/
      domain/models/                 # Call type, phase, and control state
      domain/services/               # Call service interface
      data/                          # UI-only preview call service
      presentation/cubit/            # Session, timer, controls, and cleanup
      presentation/pages/            # Shared voice/video call screen
      presentation/widgets/          # Rings, avatar, actions, and video stages
    chat/
      domain/models/                 # Conversations, messages, typed attachments
      domain/repositories/           # Message repository contract
      domain/services/               # Recording, playback and media-copy interfaces
      data/                          # In-memory messages and native media services
      presentation/cubit/            # Inbox, conversation, recording and playback state
      presentation/pages/            # Inbox and conversation screens
      presentation/widgets/          # Header, body, composer, emoji, media and voice UI
    create_post/
      domain/models/                 # PostDraft, GalleryAttachment, typed choices
      domain/validation/             # PostDraftValidator
      presentation/cubit/            # Draft and gallery state
      presentation/helpers/          # Caption synchronization and option selection
      presentation/pages/            # Gallery and details screens
      presentation/widgets/          # Dialogs, media grids, form sections
    dashboard/presentation/          # Navigation Cubit, dashboard page and bottom bar
    home/presentation/               # Home page, categories and post cards
    post_detail/presentation/        # Published/sample post viewer and engagement
    posts/
      domain/                        # PostsRepository interface
      data/                          # Local storage and sample posts
      presentation/                  # Shared feed Cubit and published content
    post_analytics/
      domain/models/                 # Analytics events, periods and reports
      data/                          # Persistent/in-memory analytics repositories
      presentation/                  # Cubit, screen, tracking and chart widgets
```

Feature folders use lowercase names (`home`, `post_detail`, `create_post`), with
`domain/models`, `presentation/cubit`, `presentation/pages`, and
`presentation/widgets` as siblings at the appropriate layer. Widget filenames
state what they contain, such as `post_detail_screen.dart`,
`create_post_details_screen.dart`, and `home_post_card.dart`. Project imports
consistently use `package:nini/...`.

`main.dart` is unchanged. Two small export files retain the exact imports it
already uses; they contain no implementation:

- `features/dashboard/presentation/page/dashboard_shellscreen/dahboard_screen.dart`
  exports `features/dashboard/presentation/pages/dashboard_screen.dart`.
- `features/post_analytics/presentation/domain/cubit/post_analytics_cubit.dart`
  exports `features/post_analytics/presentation/cubit/post_analytics_cubit.dart`.

Creation models `PostDraft` and `GalleryAttachment` live in
`features/create_post/domain/models/`. Repositories import these models directly,
without importing presentation Cubits. `PostDraftValidator` contains the existing
required-field and schedule checks; presentation maps its issues to the same
Persian messages in the same order.

`CreatePostDetailsScreen` was reduced from 449 to 194 lines. It composes basic
details, pricing/inventory, options, and publish actions from
`widgets/post_form_sections/`:

| Widget | Responsibility |
| --- | --- |
| `PostBasicDetailsSection` | Post type, title, rich caption, and per-attachment alt text. |
| `PostPricingInventorySection` | Price, discount, availability, and stock quantity. |
| `PostOptionsSection` | Preparation time, unit, schedule, address, features, and tags. |
| `PostPublishActions` | Existing Cancel/Publish actions and loading appearance. |

Individual options use
`BlocSelector` so unrelated draft edits do not rebuild the entire screen.
`PostCaptionSynchronizer` handles editor-to-draft synchronization. The screen
still owns and disposes its controllers, handles loading state and navigation,
and flushes the caption before the existing publish operation.

`shared/models/post/` provides typed `PostDetails`, `PostAddress`, `PostSchedule`,
and `PostFeature` values. Views read those properties instead of casting metadata
maps. The legacy `metadata` constructor/accessor and saved JSON format remain
compatible, including unknown metadata keys and original date representations.
No saved-post migration is required.

All client icon paths are centralized in `AppIcons`. `AppTextField.textDirection`
can be configured and defaults to the existing RTL behavior. Each analytics chart
has its own file, with `analytics_charts.dart` exporting the four public widgets.
Their drawing logic, colors, values, and interactions are unchanged:

- `analytics_line_chart.dart`: area/line chart, point selection, and tooltips.
- `analytics_radar_chart.dart`: current/previous-period radar plot.
- `analytics_polar_chart.dart`: impressions polar area plot.
- `analytics_orders_chart.dart`: seven-day orders/bookings bars.

## Verification

Run the complete checks from the repository root:

```sh
flutter analyze
flutter test
```

| Test file | Main coverage |
| --- | --- |
| [widget_test.dart](test/widget_test.dart) | Bundled client icons, Home/tab navigation, and post icon actions. |
| [theme_test.dart](test/theme_test.dart) | Theme preferences, system changes, contrast, and state preservation. |
| [app_button_test.dart](test/app_button_test.dart) | Primary/outlined buttons, loading spinners, and theme updates. |
| [create_post_options_test.dart](test/create_post_options_test.dart) | Draft serialization, dialogs, validation, cancellation, map selection, and rich caption formatting. |
| [publish_post_test.dart](test/publish_post_test.dart) | Media copying, reload, save recovery, duplicate-submit protection, navigation, and published content. |
| [post_analytics_test.dart](test/post_analytics_test.dart) | Event persistence, aggregation, impressions, chart controls, narrow screens, and analytics navigation. |
| [post_sheet_theme_test.dart](test/post_sheet_theme_test.dart) | Opposite palettes for all create-post sheets, button/icon contrast, page-theme isolation, and live theme changes without losing form input. |
| [gallery_loading_test.dart](test/gallery_loading_test.dart) | Per-tab permission/query isolation, full/limited access, permission refresh races, partial-page continuation, retry, file selection, and lifecycle refresh. |
| [chat_attachments_test.dart](test/chat_attachments_test.dart) | Paperclip sheet, photo selection, picker routing, camera outcomes, location sharing, cancellation, and both themes. |
| [calls_test.dart](test/calls_test.dart) | Call navigation, answer/end, timer cleanup, control states, draft preservation, and both themes. |
| [chat_test.dart](test/chat_test.dart) | Voice lifecycle, media copying, playback races, deletion/blocking, emoji insertion, gallery reuse, and both themes. |
| [post_models_test.dart](test/post_models_test.dart) | Lossless legacy metadata, typed details, validation precedence, schedule boundaries, and configurable text direction. |

The latest completed application verification on **30 October 2026** reported
**98 passing tests** and no analyzer issues. During the refactor, four temporary
before/after comparisons also confirmed identical form pixels at widths 320 and
390 in both light and dark mode. Those comparison fixtures were removed after
verification; they are not part of the current 98-test suite. The chat changes add
14 focused tests to the existing 50, followed by 7 call-preview tests and 13
attachment-flow tests. Gallery loading fixes add another 11 tests; sheet theme checks add 3. Chat media
layouts were also rendered and
checked in light and dark mode; native microphone behavior still needs a physical
phone check.


## Chat, voice notes, and attachments

Open the Home messages button, then choose a conversation. The feature lives in
`lib/features/chat/`, using the same `domain`, `data`, and `presentation` folders
as the other features. `main.dart` is unchanged. Shared client artwork is referenced
through `AppIcons`, and chat controls use Persian labels and the current theme.

### Conversation actions

- Type a message and tap Send, or use the keyboard send action. Empty messages
  are ignored.
- When the text field is empty, the Send button becomes a microphone. Tap it to
  request microphone permission and start recording. Tap Stop to review the
  recording, then Send or Cancel. Very short recordings are discarded.
- Sent voice notes have play/pause, duration, and a seek slider. Only one note can
  play at a time. Loading/playback failures show a localized error and allow retry.
- Recording stops into a reviewable draft when the app is interrupted or covered
  by another route; playback pauses. Leaving the conversation cancels unsent
  recordings and releases the recorder, player, subscriptions, and timers.
- The photo button opens the existing gallery's Photo tab. The paperclip opens
  the attachment bottom sheet: Document, Location, Camera, and Gallery, above a
  four-column grid of recent photos. Select thumbnails and tap Send to send them
  directly. Document opens the existing File tab; Gallery opens the full gallery,
  which retains its Video tab. All photo browsing reuses `GalleryCubit` and
  `GalleryGrid`; the full picker also retains `GalleryPreview`. No path enters
  the post-details form.
- Photo messages open a zoomable viewer. Documents and videos open through the
  device's native file viewer. Original picker files are copied into a private
  chat cache before a message is added; temporary picker paths are not retained.
- The emoji button toggles an in-app picker using the device's emoji glyphs.
  Emojis are inserted at the current text selection. The keyboard button returns
  to text input; the operating system's own emoji key is also available. This
  does not programmatically switch the system keyboard into its emoji tab.

The three-dot menu offers **Delete messages**, **Clear conversation**, and
**Block/Unblock**. Choosing Delete messages, or long-pressing a bubble, enters
selection mode. Tap messages to select/deselect them, use Select all if needed,
and tap the trash action to confirm deletion. One selected text message can also
be copied from the menu. Delete and Clear affect this device's conversation only.

Blocking disables text, voice, and attachment sends. It also cancels an active
recording. Unblock restores the composer. Blocking while a media copy is in flight
prevents that pending send and removes the unused cached copy. Deleting messages
removes their owned media copies and refreshes the inbox preview. Missing cached
files, denied permissions, and failed media exports show recoverable errors.

### Chat components

| Component | Responsibility |
| --- | --- |
| `domain/models/chat_message.dart`, `chat_attachment.dart`, and `chat_location.dart` | Text, media metadata, voice duration, and validated location coordinates/address. |
| `domain/repositories/chat_messages_repository.dart` | Message reads/adds, selected deletion, clearing, and local block state. |
| `data/in_memory_chat_repository.dart` | Existing demo conversations' messages and block flags for the current app session. |
| `data/local_chat_media_store.dart` | Streaming file copies, gallery export fallback, optional video thumbnails, batch rollback, and owned-cache cleanup. |
| `data/device_voice_recorder.dart` | Microphone permission and mono AAC/M4A capture; native recorder creation is deferred until needed. |
| `data/just_audio_chat_player.dart` | One lazily created native audio player per conversation. |
| `data/device_chat_camera.dart` | Native photo capture and a streaming file adapter for the existing gallery media pipeline. |
| `presentation/helpers/chat_attachment_flow.dart` | Sheet choices, existing gallery navigation, camera cancellation/errors, and address-picker results. |
| `presentation/cubit/` | Inbox previews, send guards, selection/block state, recording lifecycle, and playback/load cancellation. |
| `presentation/widgets/` | Conversation header/body, confirmation dialog, composer, attachment/voice bubbles, recording panel, and emoji panel. |

`ConversationScreen` accepts repository, media store, recorder, and audio-player
interfaces for tests or future integrations. Its inbox callback updates previews
for text, voice, files, deletion, and blocking. Returning to or reopening an inbox
refreshes previews and block state from the session repository.

### Packages and native setup

The chat additions use [record](https://pub.dev/packages/record),
[just_audio](https://pub.dev/packages/just_audio),
[emoji_picker_flutter](https://pub.dev/packages/emoji_picker_flutter), and
[open_filex](https://pub.dev/packages/open_filex), plus
[image_picker](https://pub.dev/packages/image_picker) for camera capture only.
The existing photo-manager and file-picker packages still supply the gallery/file selection flow.

- Android: `RECORD_AUDIO` is declared, with microphone hardware optional so the
  app can still be installed on devices without a microphone. Runtime microphone
  permission is requested when Record is tapped.
- iOS: `NSMicrophoneUsageDescription` explains voice-note recording in Persian,
  and `NSCameraUsageDescription` explains chat photo capture. The existing
  photo-library description covers both posts and conversations.
- Camera capture uses image_picker's native camera flow. Android requires no
  additional camera permission declaration for this flow. Gallery browsing still
  uses the existing photo-manager UI; image_picker does not replace it.
- Gallery permissions remain the existing Android/iOS setup documented above.

After pulling these native additions, fully stop the old app and rebuild it:

```sh
flutter pub get
flutter run
```

Hot reload alone does not install the new native plugins or microphone permission
configuration. Check recording, audible playback, gallery access, and external
file viewing on a physical phone before release.

### Current chat storage scope

The chat repository is still **in memory**: there is no account connection,
network delivery, server-side blocking, real read receipts, or durable conversation
history. Sent attachments are copied into private temporary cache files, while
message records and block flags last for the running app session. Reopening a
conversation in that session retains them; restarting the app resets the demo
chat state. The operating system may clear temporary media. Calling is an
interactive UI preview, as described below; it does not connect devices.

`test/chat_test.dart` covers microphone denial, recording preview/cancel/disposal,
short recordings, permission responses after disposal, all-send blocking,
blocking during media preparation, retries, selective deletion, inbox previews,
media-copy rollback, source-file preservation, playback/load races, emoji input,
the existing gallery return flow, voice-note sending, and 320/390-width layouts
in both themes. Native recording/playback interfaces are replaced with fakes in
these tests; they do not verify the phone's microphone hardware.

The chat native-plugin additions were verified with Android debug APK and iOS
simulator builds. Call previews add no native plugins or permissions.


## Voice and video call UI previews

The conversation header now routes its phone and video buttons to `CallScreen`
in `lib/features/calls/`. As requested, this is **UI only**: no signaling,
remote media, device microphone/camera capture, or incoming system notifications
are implemented. No additional calling package or account setup is required.
A small Persian preview label distinguishes these screens from real calls.

- **Voice:** opens the incoming-call reference layout with concentric rings,
  contact avatar/name, and red decline, green answer, and yellow message buttons.
  Answer enters the active preview and starts the elapsed timer. Microphone and
  speaker buttons toggle their displayed states.
- **Video:** opens the active reference layout with a full-screen sample image,
  small local-preview tile, name, timer, back arrow, and bottom call controls.
  Camera-off replaces the small preview with a disabled-camera indicator.
  Camera switch toggles the front/rear preview. The bottom chevron expands the
  speaker option. White overlays remain readable over the image in either theme.
- **Exit:** End, Decline, Message, and Back close the preview and return to the
  conversation. Message returns to the existing composer; text drafts remain.
  Closing the route cancels its timer and releases the preview session.
- Blocked contacts and an active recording/attachment send disable call entry.

`PreviewCallService` owns the simulated session and control states; `CallCubit`
coordinates actions and elapsed time. The `CallService` interface is separate
from the screen, so a later RTC implementation can replace the preview.
`CallScreen` accepts optional local/remote video widgets for that later adapter.
These extension points do not currently provide network calling.

The preview reuses the app's bundled `assets/img1.png`, `img2.png`, and `img3.png`
as sample pictures rather than adding remote image requests. A contact's existing
avatar is used when available. Replace the preview pictures with client-provided
high-resolution portraits if needed; they are static images, not video feeds.
All new labels are in `AppStrings`. Voice surfaces inherit the app theme, and
red/green/yellow call actions follow the supplied reference colors.

`test/calls_test.dart` contains seven tests covering the preview state flow,
320/390-width layouts in both themes, navigation from chat, preserved drafts,
answer/decline/end/message/back, mute/speaker/camera controls, front/rear previews,
and elapsed-time advancement/cleanup. No real call is made by these tests.


### Paperclip attachment flow

`ChatAttachmentSheet` lives in
`lib/features/chat/presentation/widgets/attachment_sheet/`. Its drag handle,
four circular actions, and four-column recent-photo grid follow the supplied
reference. It inherits the app theme and uses the original client `AppIcons`.
`GalleryGrid(compact: true)` removes the post toolbar/tab selector only inside
this sheet; the default post-gallery layout is unchanged. Selection reveals the
shared `AppButton` with the selected count. Failed thumbnails show a fallback;
denied gallery access retains Settings/Retry and the other attachment actions.

- **Document / Gallery:** close the sheet and open the existing full picker on
  File / Photo respectively. Send returns the selected attachments to chat;
  cancellation sends nothing.
- **Camera:** closes the sheet and opens the phone's native photo capture/review
  flow. Confirming copies the photo into the same private chat media cache and
  adds an image message. Cancel sends nothing; permission failures show a Persian
  error and restore the composer. A full app rebuild installs the new plugin.
- **Location:** reuses `AddressDialog` and `LocationMap`. Choose a pin and enter
  an address, then tap Send location. The selected coordinates/address become a
  typed `ChatLocation` message with an Open map action. Tapping it opens the pin
  in the external map viewer. This is manual pin sharing and needs no GPS access.

The conversation pauses voice playback before opening the sheet. Its picker
busy state prevents overlapping actions without showing a background loading
spinner. Dismissal retains the text draft. The conversation checks its existing
send/block state after pickers return, and owns media copying and message state.
Location messages use the same local/session repository as other messages.

`test/chat_attachments_test.dart` adds 13 tests for light/dark 320/390-width
layouts, actual grid selection and direct sending, file/photo-tab routing,
camera success/cancel/permission denial, map selection results, blocked/invalid
locations, draft preservation, denied gallery access, and camera-file streaming.
Native capture is replaced with a fake in widget tests; camera hardware still
needs a physical-phone check. Android debug and iOS simulator builds succeed
with the camera plugin.
