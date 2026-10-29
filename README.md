# Nini

Flutter app with the client's original icon collection and shared light/dark themes.

## Run the app

```sh
flutter pub get
flutter run
```

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

The create-post gallery uses this setup for selecting photos, videos, and files.
Request permission on the gallery action with
`PhotoManager.requestPermissionExtend()`. Accept `state.hasAccess`, including
limited access, before querying albums with `PhotoManager.getAssetPathList()`.
Handle denial in the UI. `AssetEntityImage` / `AssetEntityImageProvider` display
assets through the image-provider package. Native changes require a full rebuild.

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
| Client PNG icons and built-in icons on page surfaces | Black | White |
| Primary elevated/filled button backgrounds | Black | White |
| Primary button labels, icons, and loading spinners | White | Black |
| Outlined/text/icon button labels and icons | Black | White |
| Outlined button backgrounds | White with gray border | Black with gray border |
| Placeholder and selected-chip surfaces | Light gray | Dark gray |
| Dividers and borders | Light gray | Gray |

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
color, and their shapes/transparency are preserved. The PNG files stay unchanged.
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
foregrounds, real theme-menu interaction, rendered text/PNG colors, system changes,
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
| `shared/models/post/post_item.dart` and `post_media.dart` | Post data, attachment types, metadata, and JSON serialization. |
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

All 13 supplied PNG sheets are preserved, unchanged, in
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

Only the 13 individual-icon folders are registered in [`pubspec.yaml`](pubspec.yaml).
Original sheets and the extraction manifest are kept for reference and are not
bundled into the app.

## How icons are used

[`AppIcons`](lib/core/icons/app_icons.dart) holds the paths currently used by the
app. [`AppIcon`](lib/shared/widgets/app_icons/app_icon.dart) displays an asset with its
transparency and aspect ratio preserved.

```dart
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

// Inherits black in light mode and white in dark mode.
const AppIcon(AppIcons.search, size: 28);

// Give an interactive control its existing label and callback.
IconButton(
  tooltip: 'Search',
  onPressed: onSearch,
  icon: const AppIcon(AppIcons.search, size: 28),
);

// For a meaningful standalone image, supply an accessibility label.
const AppIcon(AppIcons.cart, size: 28, semanticLabel: 'Cart');
```

Use the first two imports with `package:flutter/material.dart` when constructing
buttons. Existing app controls retain their Persian labels, tooltips, callbacks,
counts, and layout sizes.

| App location/action | Client asset (relative to `assets/icons/`) |
| --- | --- |
| Bottom navigation: home | `general/home-04.png` |
| Bottom navigation: cart | `finance/cart.png` |
| Create tab and add category | `general/plus-01.png` |
| Search tab | `general/search-01.png` |
| Profile/avatar fallback | `images/image-avatar.png` |
| Home header: theme menu | `weather/sun-03.png` / `weather/moon-01.png` |
| Home header: messages | `travel_location/pointer-01.png` |
| Home and post menus | `general/dot-vertical.png` |
| Post detail: back | `arrows/chevron-left.png` |
| Post detail: bookmark | `general/favourite.png` |
| Post detail: like | `general/heart.png` |
| Post detail: share | `general/share.png` |
| Unavailable product/gallery image | `images/image-x.png` |
| Product price tag | `finance/tag.png` |

`AppIcon` inherits the current `IconTheme` color, falling back to
`colorScheme.onSurface`: black in light mode and white in dark mode. Its optional
`color` argument is an explicit override; normal app controls leave it unset.
Use `selected: true` to add a subtle background highlight while keeping the same
foreground. Like/bookmark toggles also expose their state to accessibility services.
The existing rating star and plain comment bubble remain built-in icons because
the supplied collection has no equivalent; notification bubbles have additional
symbols and the weather stars have a different meaning.

## How to add another icon

1. Put the original transparent PNG in its category folder, for example
   `assets/icons/general/new-icon.png`. Export individual icons from the designer
   when available; do not use an entire labeled sheet as a button image.
2. Existing category folders are already registered. If adding a new category,
   add its directory under `flutter: assets:` in `pubspec.yaml`; Flutter does not
   recursively include arbitrary subdirectories from the existing `assets/` entry.
3. Add a descriptive constant in `lib/core/icons/app_icons.dart`:

   ```dart
   static const newIcon = 'assets/icons/general/new-icon.png';
   ```

4. Use `const AppIcon(AppIcons.newIcon, size: 24)` at the relevant control. Keep
   the control's tooltip, accessibility label, and existing callback. Leave
   `color` unset so the icon follows light/dark mode automatically.
5. Run `flutter pub get` and fully restart the app after changing asset entries.

Icons already in this collection can be used immediately by adding an `AppIcons`
constant for their existing path. No dependency or icon font is needed.

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
and post analytics use Persian copy from `lib/core/localization/app_strings.dart`.
This includes buttons, hints, validation errors, tooltips, chart legends, period
menus, month/weekday labels, and numeric summaries. Add future UI labels there
and reference `AppStrings` in widgets instead of hard-coding English text.

The app locale remains `fa_IR`. Material date/time controls use its localized
labels. The caption editor explicitly loads Persian Quill/Flutter localization;
Undo/Redo have Persian tooltip overrides because the installed Quill Persian
translations leave those two labels in English. Input text reads right to left.
Page navigation, photo order and chart timelines keep the existing layout.

Numbers in analytics are formatted with `AppStrings.persianDigits` for display.
Chart month names are Persian names of Gregorian months; this change does not
switch the stored calendar to Jalali. IDs, enum names, dates, JSON keys, event
values and user-entered content retain their original values. Previously saved
English Product/Services categories also display their Persian labels on home
cards without rewriting saved records.


## Code organization and behavior-preserving cleanup

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

`CreatePostDetailsScreen` composes basic details, pricing/inventory, options, and
publish actions from `widgets/post_form_sections/`. Individual options use
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
Their drawing logic, colors, values, and interactions are unchanged.
