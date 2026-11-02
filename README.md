# Nini / HYWORK

A Flutter frontend for a Persian marketplace app. The Dart package is `nini`,
the app locale is `fa_IR`, and the current Home reference uses the **HYWORK** wordmark.
The client repository is [mobile-hywork](https://github.com/mojtaba-zarabi/mobile-hywork).

This README describes the current working tree, reviewed on **2 November 2026**.
The project currently focuses on UI. Posts, profile categories, analytics, cart
items, and existing order snapshots save on the device. Profile editing,
saved-location labels, notifications, and Wallet currently provide UI previews
with temporary state.
Authentication, remote product/search APIs, real payment gateways, synchronized
chat, and real voice/video calling are not connected.

## Contents

- [Current implementation](#current-implementation)
- [Setup and run](#setup-and-run)
- [Project structure](#project-structure)
- [Important file locations](#important-file-locations)
- [Startup and shared providers](#startup-and-shared-providers)
- [Dashboard and navigation](#dashboard-and-navigation)
- [Home screen](#home-screen)
- [Cart and local checkout](#cart-and-local-checkout)
- [Search screen and city selection](#search-screen-and-city-selection)
- [Profile screen](#profile-screen)
- [Settings list, profile edit, and locations](#settings-list-profile-edit-and-locations)
- [Notifications](#notifications)
- [Wallet](#wallet)
- [Folder, import, and coding conventions](#folder-import-and-coding-conventions)
- [Shared colors and reusable widgets](#shared-colors-and-reusable-widgets)
- [Light and dark mode](#light-and-dark-mode)
- [Gallery packages and permissions](#gallery-packages-and-permissions)
- [Create-post details, dialogs, and caption editor](#create-post-details-dialogs-and-caption-editor)
- [Publishing and the shared post feed](#publishing-and-the-shared-post-feed)
- [Profile categories and post edit/delete](#profile-categories-and-post-editdelete)
- [Local storage and backend handoff](#local-storage-and-backend-handoff)
- [Client icons](#client-icons)
- [How icons are used](#how-icons-are-used)
- [How to add another icon](#how-to-add-another-icon)
- [Re-extract or verify the original collection](#re-extract-or-verify-the-original-collection)
- [Post analytics](#post-analytics)
- [Persian text on the new screens](#persian-text-on-the-new-screens)
- [Chat, voice notes, and attachments](#chat-voice-notes-and-attachments)
- [Voice and video call UI previews](#voice-and-video-call-ui-previews)
- [Packages and platform configuration](#packages-and-platform-configuration)
- [Verification](#verification)
- [Common changes and troubleshooting](#common-changes-and-troubleshooting)
- [Repository workflow](#repository-workflow)

## Current implementation

| Area | Current behavior and scope |
| --- | --- |
| Startup | `main.dart` starts `ResponsiveConfig` and `MyApp`; app configuration and shared providers are in `lib/app/`. |
| Dashboard | Native `PageView` with Home, Cart, Create, Search, and Profile. Startup opens Home. |
| Home | HYWORK header, notification bell with unread count, and six sample phone cards with image, badges, engagement, pricing, stock, and add-to-cart. This is a fixed sample feed. |
| Cart | Quantities, stock limits, status filters, swipe removal, checkout details/totals, bank selection, existing order history, navigation badge, and Home add-to-cart. No payment-submit action. |
| Search | Suggestions, inline city selection, city/query filtering of bundled samples, empty states, and post-detail navigation. |
| Profile | Identity, statistics, category filters, shared locally saved post grid, chat, theme menu, and three-dot settings entry. |
| Profile categories | Create, rename, select, and delete persisted tabs; choose a tab when creating/editing a post. Removing a tab preserves its posts in All. |
| Post creation | Photo/video/file selection, rich caption, title, category, pricing, stock, type, unit, preparation time, schedule, address, features, tags, and alt text. |
| Post edit/delete | Owner menu in post details; prefilled full editor, attachment add/remove/replace, discard confirmation, and red delete confirmation. Existing Profile samples can be managed too. |
| Settings list | Seventeen rows. Profile setting, Locations, and Wallet open detail screens; the remaining rows are placeholders. |
| Profile edit | Photo picker, personal fields, birth picker, gender, and bio. Screen-local form; Done closes without updating an account or Profile. |
| Locations | Map preview, label entry, add/select labels. Temporary state with no account persistence or GPS. |
| Notifications | Home bell opens searchable sample notifications; tapping a row clears its unread count for the lifetime of Home. No push service or durable read state. |
| Wallet | Balance/transactions, Top Up, Withdraw, and withdrawal summary. Amount controls, bank radios, and a local OTP countdown are UI previews only. |
| Colors and localization | Central `AppColors`, light/dark/system themes, Persian string catalogs, right-aligned text, and Persian display digits. |
| Analytics | Five chart sections and device-local view/impression/watch/interaction tracking for published posts. Sample analytics remain distinct. |
| Chat | Demo inbox, text/voice/media/location messages, emoji, delete/clear/block actions, and local attachment copies. Conversation history is session-only. |
| Calls | Interactive voice/video previews with timers and controls; no live calling service. |
| Assets | Central icon paths, client SVG/PNG collections, bank logos, YekanBakh font, bundled sample photos, and a withdrawal illustration. |
| Verification scope | The `test/` directory was removed at the project's current UI-only stage. This README update does not run tests, builds, or device checks. |

## Setup and run

### Requirements

- Flutter with a bundled Dart SDK satisfying **`^3.13.3`**, as declared in
  [pubspec.yaml](pubspec.yaml).
- The Flutter version is not separately pinned; check `flutter --version` in your
  checkout before choosing a compatible SDK.
- Android/iOS development tooling for native gallery, microphone, camera,
  playback, and external-file flows.
- Internet for Home's network product photo and OpenStreetMap tiles.

From the repository root:

```sh
flutter pub get
flutter devices
flutter run
```

For a fresh client checkout:

```sh
git clone https://github.com/mojtaba-zarabi/mobile-hywork.git
cd mobile-hywork
flutter pub get
flutter run
```

Choose a device explicitly when needed:

```sh
flutter run -d <device-id>
```

After native plugin, permission, entitlement, or asset-manifest changes, stop and
rebuild the app. Hot reload alone does not install those changes. Platform folders
are present for Android, iOS, macOS, web, Linux, and Windows; native media features
still need checks on the platform being shipped.

## Project structure

| Path | Responsibility |
| --- | --- |
| [`lib/main.dart`](lib/main.dart) | Flutter initialization and application entry point. |
| [`lib/app/`](lib/app/) | `MyApp`, app configuration, dependency injection, and shared Cubit ownership. |
| [`lib/core/`](lib/core/) | Theme/colors, localization, icon paths, responsiveness, and animation helpers. |
| [`lib/features/`](lib/features/) | Feature-owned pages, widgets, state, data adapters, models, and contracts. |
| [`lib/shared/`](lib/shared/) | Cross-feature post models and reusable UI components. |
| [`assets/`](assets/) | Bundled pictures, fonts, bank logos, wallet artwork, and icon collections/reference sheets. |
| [`tool/`](tool/) | Icon manifests, extraction scripts, and the SVG importer. |
| `android/`, `ios/`, `macos/`, `web/`, `linux/`, `windows/` | Flutter runners and platform configuration. Native feature support still needs target-device verification. |
| [`pubspec.yaml`](pubspec.yaml) / [`pubspec.lock`](pubspec.lock) | Dependency/asset declarations and resolved dependency versions. |
| [`analysis_options.yaml`](analysis_options.yaml) | Lints and analysis exclusions. |
| [`.gitignore`](.gitignore) / [`.metadata`](.metadata) | Git exclusions and Flutter project metadata. |
| `build/`, `.dart_tool/`, `.flutter-plugins-dependencies` | Generated output/plugin metadata; not feature source. |

The inventory below includes **all 305 Dart files currently under `lib/`**.
It reflects the actual mixed `page/` and `pages/` paths; use these paths when
importing. Individual icon assets and generated build/cache files are not expanded.
There is currently no `test/` directory.

<details>
<summary>Expand the complete lib folder and file structure</summary>

```text
lib/
├── app/
│   ├── app.dart
│   └── app_providers.dart
├── core/
│   ├── animation/
│   │   ├── animation.dart
│   │   ├── rive_asset_animation.dart
│   │   ├── screen_entrance.dart
│   │   └── staggered_entrance.dart
│   ├── icons/
│   │   └── app_icons.dart
│   ├── localization/
│   │   ├── app_strings.dart
│   │   ├── cart_strings.dart
│   │   ├── location_strings.dart
│   │   ├── notification_strings.dart
│   │   ├── persian_feature.dart
│   │   ├── profile_edit_strings.dart
│   │   ├── profile_post_strings.dart
│   │   ├── profile_settings_strings.dart
│   │   ├── search_strings.dart
│   │   └── wallet_strings.dart
│   ├── responsiveness/
│   │   ├── app_responsiveness/
│   │   │   └── app_responsiveness.dart
│   │   ├── fold_aware_layout/
│   │   │   └── fold_aware_layout.dart
│   │   └── responsive_config/
│   │       └── config.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_theme.dart
│       ├── theme_cubit.dart
│       └── theme_mode_menu.dart
├── features/
│   ├── calls/
│   │   ├── data/
│   │   │   └── preview_call_service.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── call_session.dart
│   │   │   └── services/
│   │   │       └── call_service.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── call_cubit.dart
│   │       ├── pages/
│   │       │   └── call_screen.dart
│   │       └── widgets/
│   │           ├── call_action_button.dart
│   │           ├── call_avatar.dart
│   │           ├── call_controls.dart
│   │           └── call_video_stage.dart
│   ├── cart/
│   │   ├── data/
│   │   │   ├── demo_cart_items.dart
│   │   │   └── local_cart_repository.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── cart_item.dart
│   │   │   │   ├── cart_order.dart
│   │   │   │   ├── cart_order_status.dart
│   │   │   │   ├── cart_snapshot.dart
│   │   │   │   └── payment_method.dart
│   │   │   └── repositories/
│   │   │       └── cart_repository.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── cart_cubit.dart
│   │       │   └── cart_state.dart
│   │       ├── helpers/
│   │       │   ├── cart_format.dart
│   │       │   └── cart_labels.dart
│   │       ├── pages/
│   │       │   └── cart_screen.dart
│   │       └── widgets/
│   │           ├── cart_amount_dialog/
│   │           │   └── cart_amount_dialog.dart
│   │           ├── cart_checkout/
│   │           │   └── cart_checkout.dart
│   │           ├── cart_delete_background/
│   │           │   └── cart_delete_background.dart
│   │           ├── cart_dialog_actions/
│   │           │   └── cart_dialog_actions.dart
│   │           ├── cart_empty_state/
│   │           │   └── cart_empty_state.dart
│   │           ├── cart_header/
│   │           │   └── cart_header.dart
│   │           ├── cart_item_badge/
│   │           │   └── cart_item_badge.dart
│   │           ├── cart_item_card/
│   │           │   └── cart_item_card.dart
│   │           ├── cart_item_image/
│   │           │   └── cart_item_image.dart
│   │           ├── cart_items_list/
│   │           │   └── cart_items_list.dart
│   │           ├── cart_order_history/
│   │           │   └── cart_order_history.dart
│   │           ├── cart_payment_methods/
│   │           │   └── cart_payment_methods.dart
│   │           ├── cart_payment_summary/
│   │           │   └── cart_payment_summary.dart
│   │           ├── cart_quantity_button/
│   │           │   └── cart_quantity_button.dart
│   │           ├── cart_section/
│   │           │   └── cart_section.dart
│   │           ├── cart_status_filter/
│   │           │   └── cart_status_filter.dart
│   │           ├── cart_status_menu/
│   │           │   └── cart_status_menu.dart
│   │           ├── cart_storage_notice/
│   │           │   └── cart_storage_notice.dart
│   │           └── cart_tabs/
│   │               └── cart_tabs.dart
│   ├── chat/
│   │   ├── data/
│   │   │   ├── demo_chats.dart
│   │   │   ├── device_chat_camera.dart
│   │   │   ├── device_voice_recorder.dart
│   │   │   ├── in_memory_chat_repository.dart
│   │   │   ├── just_audio_chat_player.dart
│   │   │   └── local_chat_media_store.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── chat_attachment.dart
│   │   │   │   ├── chat_conversation.dart
│   │   │   │   ├── chat_location.dart
│   │   │   │   └── chat_message.dart
│   │   │   ├── repositories/
│   │   │   │   └── chat_messages_repository.dart
│   │   │   └── services/
│   │   │       ├── chat_audio_player.dart
│   │   │       ├── chat_media_store.dart
│   │   │       └── voice_recorder.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── chat_inbox_cubit.dart
│   │       │   ├── conversation_cubit.dart
│   │       │   ├── voice_playback_cubit.dart
│   │       │   └── voice_recording_cubit.dart
│   │       ├── helpers/
│   │       │   ├── chat_attachment_flow.dart
│   │       │   └── chat_message_labels.dart
│   │       ├── pages/
│   │       │   ├── chat_inbox_screen.dart
│   │       │   └── conversation_screen.dart
│   │       └── widgets/
│   │           ├── attachment_sheet/
│   │           │   └── chat_attachment_sheet.dart
│   │           ├── chat_conversation_tile/
│   │           │   └── chat_conversation_tile.dart
│   │           ├── conversation_actions/
│   │           │   └── chat_action_dialog.dart
│   │           ├── conversation_body/
│   │           │   └── conversation_body.dart
│   │           ├── conversation_header/
│   │           │   └── conversation_header.dart
│   │           ├── emoji_panel/
│   │           │   └── chat_emoji_panel.dart
│   │           ├── message_bubble/
│   │           │   ├── chat_attachment_view.dart
│   │           │   ├── chat_location_view.dart
│   │           │   └── chat_message_bubble.dart
│   │           ├── message_composer/
│   │           │   └── chat_message_composer.dart
│   │           ├── voice_message/
│   │           │   └── chat_voice_player.dart
│   │           └── voice_recording/
│   │               └── voice_recording_panel.dart
│   ├── create_post/
│   │   ├── data/
│   │   │   └── gallery_library_changes.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── gallery_attachment.dart
│   │   │   │   ├── post_draft.dart
│   │   │   │   └── post_options.dart
│   │   │   └── validation/
│   │   │       └── post_draft_validator.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── create_post_cubit.dart
│   │       │   └── gallery_cubit.dart
│   │       ├── helpers/
│   │       │   ├── post_caption_synchronizer.dart
│   │       │   └── post_option_selection.dart
│   │       ├── pages/
│   │       │   ├── create_post_details_screen.dart
│   │       │   └── create_post_gallery_screen.dart
│   │       └── widgets/
│   │           ├── address_dialog/
│   │           │   ├── address_dialog.dart
│   │           │   └── location_map.dart
│   │           ├── alt_text_dialog/
│   │           │   └── alt_text_dialog.dart
│   │           ├── caption_editor/
│   │           │   ├── caption_editor.dart
│   │           │   └── client_caption_toolbar.dart
│   │           ├── features_dialog/
│   │           │   └── features_dialog.dart
│   │           ├── gallery_grid/
│   │           │   ├── gallery_access_notice.dart
│   │           │   └── gallery_grid.dart
│   │           ├── gallery_preview/
│   │           │   └── gallery_preview.dart
│   │           ├── post_dialog/
│   │           │   └── post_dialog.dart
│   │           ├── post_form_option_tile/
│   │           │   └── post_form_option_tile.dart
│   │           ├── post_form_sections/
│   │           │   ├── post_basic_details_section.dart
│   │           │   ├── post_options_section.dart
│   │           │   ├── post_pricing_inventory_section.dart
│   │           │   └── post_publish_actions.dart
│   │           ├── post_type_dialog/
│   │           │   └── post_type_dialog.dart
│   │           ├── preparation_time_dialog/
│   │           │   └── preparation_time_dialog.dart
│   │           ├── schedule_post_dialog/
│   │           │   └── schedule_post_dialog.dart
│   │           ├── selected_media_grid/
│   │           │   └── selected_media_grid.dart
│   │           ├── tags_dialog/
│   │           │   └── tags_dialog.dart
│   │           └── unit_dialog/
│   │               └── unit_dialog.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── dashboard_navigation_cubit.dart
│   │       ├── pages/
│   │       │   └── dashboard_screen.dart
│   │       └── widgets/
│   │           └── bottom_navbar/
│   │               ├── dashboard_bottom_nav.dart
│   │               ├── dashboard_cart_icon.dart
│   │               ├── dashboard_fold_layout.dart
│   │               └── dashboard_nav_item.dart
│   ├── home/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── home_screen.dart
│   │       └── widgets/
│   │           ├── home_badge/
│   │           │   └── home_badge.dart
│   │           ├── home_engagement_bar/
│   │           │   └── home_engagement_bar.dart
│   │           ├── home_feed_header/
│   │           │   └── home_feed_header.dart
│   │           ├── home_metric/
│   │           │   └── home_metric.dart
│   │           ├── home_notification_button/
│   │           │   └── home_notification_button.dart
│   │           ├── home_product_card/
│   │           │   └── home_product_card.dart
│   │           ├── home_product_details/
│   │           │   └── home_product_details.dart
│   │           ├── home_product_image/
│   │           │   └── home_product_image.dart
│   │           └── home_product_price/
│   │               └── home_product_price.dart
│   ├── locations/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── locations_screen.dart
│   │       └── widgets/
│   │           ├── location_label_card/
│   │           │   └── location_label_card.dart
│   │           ├── location_map_preview/
│   │           │   └── location_map_preview.dart
│   │           └── saved_location_list/
│   │               └── saved_location_list.dart
│   ├── notifications/
│   │   ├── data/
│   │   │   └── sample_notifications.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── app_notification.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── notifications_cubit.dart
│   │       │   └── notifications_state.dart
│   │       ├── pages/
│   │       │   └── notifications_screen.dart
│   │       └── widgets/
│   │           ├── notification_avatar/
│   │           │   └── notification_avatar.dart
│   │           ├── notification_header/
│   │           │   └── notification_header.dart
│   │           ├── notification_list/
│   │           │   └── notification_list.dart
│   │           ├── notification_search_field/
│   │           │   └── notification_search_field.dart
│   │           └── notification_tile/
│   │               └── notification_tile.dart
│   ├── post_analytics/
│   │   ├── data/
│   │   │   └── post_analytics_repository.dart
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── post_analytics.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── post_analytics_cubit.dart
│   │       ├── domain/
│   │       │   └── cubit/
│   │       │       └── post_analytics_cubit.dart
│   │       ├── pages/
│   │       │   └── post_analytics_screen.dart
│   │       └── widgets/
│   │           ├── activity_tracking/
│   │           │   └── post_activity_tracking.dart
│   │           ├── analytics_chart/
│   │           │   ├── analytics_charts.dart
│   │           │   ├── analytics_line_chart.dart
│   │           │   ├── analytics_orders_chart.dart
│   │           │   ├── analytics_polar_chart.dart
│   │           │   └── analytics_radar_chart.dart
│   │           ├── analytics_controls/
│   │           │   └── analytics_controls.dart
│   │           ├── analytics_header/
│   │           │   └── analytics_header.dart
│   │           ├── average_time_viewed/
│   │           │   └── average_time_viewed.dart
│   │           ├── clicks_interactions/
│   │           │   └── clicks_interactions.dart
│   │           ├── impressions/
│   │           │   └── impressions.dart
│   │           ├── orders_bookings/
│   │           │   └── orders_bookings.dart
│   │           └── total_views/
│   │               └── total_views.dart
│   ├── post_detail/
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── post_detail_cubit.dart
│   │       ├── pages/
│   │       │   └── post_detail_screen.dart
│   │       └── widgets/
│   │           ├── author_header/
│   │           │   └── post_author_header.dart
│   │           ├── content/
│   │           │   ├── post_content.dart
│   │           │   └── post_detail_body.dart
│   │           ├── engagement_bar/
│   │           │   └── post_engagement_bar.dart
│   │           ├── feature_table/
│   │           │   └── post_features_table.dart
│   │           ├── post_image_carousel/
│   │           │   └── post_image_carousel.dart
│   │           └── pricing/
│   │               └── post_pricing.dart
│   ├── posts/
│   │   ├── data/
│   │   │   ├── demo_posts.dart
│   │   │   ├── local_post_media_store.dart
│   │   │   ├── local_posts_repository.dart
│   │   │   ├── local_profile_categories_repository.dart
│   │   │   └── profile_sample_posts.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── post_media_changes.dart
│   │   │   │   └── profile_category.dart
│   │   │   ├── validation/
│   │   │   │   └── profile_category_validator.dart
│   │   │   ├── posts_repository.dart
│   │   │   └── profile_categories_repository.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── post_editor_media_cubit.dart
│   │       │   ├── post_editor_media_state.dart
│   │       │   ├── posts_cubit.dart
│   │       │   ├── posts_state.dart
│   │       │   ├── profile_categories_cubit.dart
│   │       │   └── profile_categories_state.dart
│   │       ├── helpers/
│   │       │   ├── confirm_discard_post_changes.dart
│   │       │   ├── manage_post_actions.dart
│   │       │   ├── post_draft_mapper.dart
│   │       │   └── post_editor_validation.dart
│   │       ├── pages/
│   │       │   ├── edit_post_screen.dart
│   │       │   └── profile_categories_screen.dart
│   │       └── widgets/
│   │           ├── category_delete_sheet/
│   │           │   └── category_delete_sheet.dart
│   │           ├── category_editor_sheet/
│   │           │   └── category_editor_sheet.dart
│   │           ├── category_sheet_actions/
│   │           │   └── category_sheet_actions.dart
│   │           ├── edit_post_form/
│   │           │   └── edit_post_form.dart
│   │           ├── post_category_selector/
│   │           │   └── post_category_selector.dart
│   │           ├── post_delete_actions/
│   │           │   └── post_delete_actions.dart
│   │           ├── post_delete_sheet/
│   │           │   └── post_delete_sheet.dart
│   │           ├── post_editor_actions/
│   │           │   └── post_editor_actions.dart
│   │           ├── post_editor_alt_text_fields/
│   │           │   └── post_editor_alt_text_fields.dart
│   │           ├── post_editor_basic_fields/
│   │           │   └── post_editor_basic_fields.dart
│   │           ├── post_editor_features_field/
│   │           │   └── post_editor_features_field.dart
│   │           ├── post_editor_location_fields/
│   │           │   └── post_editor_location_fields.dart
│   │           ├── post_editor_media_grid/
│   │           │   └── post_editor_media_grid.dart
│   │           ├── post_editor_media_section/
│   │           │   └── post_editor_media_section.dart
│   │           ├── post_editor_media_tile/
│   │           │   └── post_editor_media_tile.dart
│   │           ├── post_editor_options_fields/
│   │           │   └── post_editor_options_fields.dart
│   │           ├── post_editor_pricing_fields/
│   │           │   └── post_editor_pricing_fields.dart
│   │           ├── post_editor_schedule_field/
│   │           │   └── post_editor_schedule_field.dart
│   │           ├── post_feature_editor_row/
│   │           │   └── post_feature_editor_row.dart
│   │           ├── post_owner_action_tile/
│   │           │   └── post_owner_action_tile.dart
│   │           ├── post_owner_actions_sheet/
│   │           │   └── post_owner_actions_sheet.dart
│   │           ├── profile_categories_body/
│   │           │   └── profile_categories_body.dart
│   │           ├── profile_category_row/
│   │           │   └── profile_category_row.dart
│   │           └── published_post_content.dart
│   ├── profile/
│   │   └── presentation/
│   │       ├── page/
│   │       │   ├── profile_screen/
│   │       │   │   └── profile_screen.dart
│   │       │   └── profile_settings_screen/
│   │       │       └── profile_settings_screen.dart
│   │       └── widgets/
│   │           ├── profile_screen_widgets/
│   │           │   ├── category_chips/
│   │           │   │   ├── category_chips.dart
│   │           │   │   └── profile_category_chip.dart
│   │           │   ├── post_grid/
│   │           │   │   └── profile_post_grid.dart
│   │           │   ├── profile_avatar/
│   │           │   │   └── profile_avatar.dart
│   │           │   ├── profile_header_actions/
│   │           │   │   └── profile_header_actions.dart
│   │           │   ├── profile_identity/
│   │           │   │   └── profile_identity.dart
│   │           │   ├── profile_post_card/
│   │           │   │   └── profile_post_card.dart
│   │           │   └── profile_stats/
│   │           │       └── profile_stats.dart
│   │           └── profile_settings_screen_widgets/
│   │               ├── profile_settings_header/
│   │               │   └── profile_settings_header.dart
│   │               ├── profile_settings_list/
│   │               │   └── profile_settings_list.dart
│   │               └── profile_settings_tile/
│   │                   └── profile_settings_tile.dart
│   ├── profile_settings/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── profile_edit_screen.dart
│   │       └── widgets/
│   │           ├── profile_birth_field/
│   │           │   └── profile_birth_field.dart
│   │           ├── profile_edit_field/
│   │           │   └── profile_edit_field.dart
│   │           ├── profile_edit_fields/
│   │           │   └── profile_edit_fields.dart
│   │           └── profile_photo_picker/
│   │               └── profile_photo_picker.dart
│   ├── search/
│   │   ├── data/
│   │   │   ├── demo_search_posts.dart
│   │   │   └── search_catalog.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── search_cubit.dart
│   │       │   └── search_state.dart
│   │       ├── page/
│   │       │   └── search_screen/
│   │       │       ├── search_screen.dart
│   │       │       └── search_view.dart
│   │       └── widgets/
│   │           └── search_screen_widgets/
│   │               ├── search_city_button/
│   │               │   └── search_city_button.dart
│   │               ├── search_city_list/
│   │               │   └── search_city_list.dart
│   │               ├── search_content/
│   │               │   └── search_content.dart
│   │               ├── search_empty_state/
│   │               │   └── search_empty_state.dart
│   │               ├── search_header/
│   │               │   └── search_header.dart
│   │               ├── search_query_field/
│   │               │   └── search_query_field.dart
│   │               ├── search_result_card/
│   │               │   └── search_result_card.dart
│   │               ├── search_results_grid/
│   │               │   └── search_results_grid.dart
│   │               └── search_suggestions/
│   │                   └── search_suggestions.dart
│   └── wallet/
│       ├── data/
│       │   └── wallet_sample_data.dart
│       ├── domain/
│       │   └── models/
│       │       └── wallet_transaction.dart
│       └── presentation/
│           ├── page/
│           │   ├── top_up_screen/
│           │   │   └── top_up_screen.dart
│           │   ├── wallet_screen/
│           │   │   └── wallet_screen.dart
│           │   ├── withdraw_screen/
│           │   │   └── withdraw_screen.dart
│           │   └── withdraw_summary_screen/
│           │       └── withdraw_summary_screen.dart
│           └── widgets/
│               ├── top_up_screen_widgets/
│               │   ├── wallet_bank_logo.dart
│               │   ├── wallet_bank_tile.dart
│               │   └── wallet_payment_methods.dart
│               ├── wallet_screen_widgets/
│               │   ├── wallet_action_tile.dart
│               │   ├── wallet_actions_row.dart
│               │   ├── wallet_balance_card.dart
│               │   ├── wallet_bottom_button.dart
│               │   ├── wallet_card_footer.dart
│               │   ├── wallet_header.dart
│               │   ├── wallet_transaction_tile.dart
│               │   └── wallet_transactions.dart
│               ├── withdraw_screen_widgets/
│               │   ├── wallet_amount_presets.dart
│               │   ├── wallet_amount_section.dart
│               │   ├── wallet_text_field.dart
│               │   ├── withdraw_account_section.dart
│               │   └── withdraw_otp_fields.dart
│               └── withdraw_summary_screen_widgets/
│                   ├── withdraw_illustration.dart
│                   ├── withdraw_summary_details.dart
│                   └── withdraw_summary_row.dart
├── shared/
│   ├── models/
│   │   └── post/
│   │       ├── post_attributes.dart
│   │       ├── post_details.dart
│   │       ├── post_item.dart
│   │       ├── post_media.dart
│   │       └── post_unit.dart
│   └── widgets/
│       ├── app_button/
│       │   └── app_button.dart
│       ├── app_icons/
│       │   └── app_icon.dart
│       ├── app_loader/
│       │   └── app_loader.dart
│       ├── app_textfield/
│       │   └── app_text_field.dart
│       ├── app_toast/
│       │   └── app_toast.dart
│       ├── post_media/
│       │   └── post_media_view.dart
│       └── settings_detail_header/
│           └── settings_detail_header.dart
└── main.dart
```

</details>

### Assets and supporting files

| Location | Contents / entry point |
| --- | --- |
| [`assets/Mask group.png`](assets/Mask%20group.png) | Default Profile avatar. |
| `assets/img1.png`, `assets/img2.png`, `assets/img3.png` | Bundled sample photos used by Profile, Search, chat, and call previews. |
| [`assets/fonts/YekanBakh-Regular.ttf`](assets/fonts/YekanBakh-Regular.ttf) | App font, registered in `pubspec.yaml`. |
| [`assets/banks/`](assets/banks/) | Bank SVG logos reused in Cart and Wallet. |
| [`assets/wallet/withdrawal.png`](assets/wallet/withdrawal.png) | Transparent withdrawal illustration used by `WithdrawIllustration`. |
| [`assets/icons/`](assets/icons/) | Client PNG groups, source sheets, and SVG groups under `vectors/`. Runtime paths are centralized in `AppIcons`; detailed extraction notes are below. |
| [`tool/client_icons.json`](tool/client_icons.json) | Original PNG crop manifest. |
| [`tool/extract_client_icons.py`](tool/extract_client_icons.py) | Extract/check original PNG crops. |
| [`tool/supplemental_icons.json`](tool/supplemental_icons.json) / [`tool/extract_supplemental_icons.py`](tool/extract_supplemental_icons.py) | Supplemental screenshot icon manifest and extraction. |
| [`tool/supplemental_vectors.json`](tool/supplemental_vectors.json) / [`tool/import_supplemental_vectors.py`](tool/import_supplemental_vectors.py) | Supplemental SVG manifest and importer. |

Asset folder registrations are in `pubspec.yaml`. Add a new folder there when
needed; putting a file on disk alone does not make an unregistered folder available
to Flutter.

## Important file locations

Start here when changing a screen or connecting a backend. Every source file is
listed in the tree above; these are the main integration and composition points.

| Work | Primary location |
| --- | --- |
| App configuration, locale, initial tab | [`app.dart`](lib/app/app.dart) |
| Root repositories and shared Cubits | [`app_providers.dart`](lib/app/app_providers.dart) |
| Dashboard tab changes / publish result | [`dashboard_screen.dart`](lib/features/dashboard/presentation/pages/dashboard_screen.dart) |
| Home data, bell, and notification state lifetime | [`home_screen.dart`](lib/features/home/presentation/pages/home_screen.dart) |
| Search page and its controllers | [`search_screen/`](lib/features/search/presentation/page/search_screen/) |
| Profile page and settings-list page | [`profile/presentation/page/`](lib/features/profile/presentation/page/) |
| Profile edit form (separate module) | [`profile_edit_screen.dart`](lib/features/profile_settings/presentation/pages/profile_edit_screen.dart) |
| Settings list destinations | [`profile_settings_list.dart`](lib/features/profile/presentation/widgets/profile_settings_screen_widgets/profile_settings_list/profile_settings_list.dart) |
| Locations preview | [`locations_screen.dart`](lib/features/locations/presentation/pages/locations_screen.dart) |
| Wallet's four screens | [`wallet/presentation/page/`](lib/features/wallet/presentation/page/) |
| Wallet sample values | [`wallet_sample_data.dart`](lib/features/wallet/data/wallet_sample_data.dart) |
| Notification samples / state | [`sample_notifications.dart`](lib/features/notifications/data/sample_notifications.dart), [`notifications_cubit.dart`](lib/features/notifications/presentation/cubit/notifications_cubit.dart) |
| Create form / gallery selection | [`create_post_details_screen.dart`](lib/features/create_post/presentation/pages/create_post_details_screen.dart), [`create_post_gallery_screen.dart`](lib/features/create_post/presentation/pages/create_post_gallery_screen.dart) |
| Draft fields and validation | [`post_draft.dart`](lib/features/create_post/domain/models/post_draft.dart), [`post_draft_validator.dart`](lib/features/create_post/domain/validation/post_draft_validator.dart) |
| Category management / full post editor | [`profile_categories_screen.dart`](lib/features/posts/presentation/pages/profile_categories_screen.dart), [`edit_post_screen.dart`](lib/features/posts/presentation/pages/edit_post_screen.dart) |
| Post owner-menu routing | [`manage_post_actions.dart`](lib/features/posts/presentation/helpers/manage_post_actions.dart) |
| Post viewer / pricing | [`post_detail_screen.dart`](lib/features/post_detail/presentation/pages/post_detail_screen.dart), [`post_pricing.dart`](lib/features/post_detail/presentation/widgets/pricing/post_pricing.dart) |
| Shared model and media serialization | [`shared/models/post/`](lib/shared/models/post/) |
| Shared widgets | [`shared/widgets/`](lib/shared/widgets/) — individual responsibilities below. |
| Fixed colors / theme roles | [`app_colors.dart`](lib/core/theme/app_colors.dart), [`app_theme.dart`](lib/core/theme/app_theme.dart) |
| Persian labels and formatting | [`core/localization/`](lib/core/localization/) — per-feature catalog map below. |
| Client icon paths | [`app_icons.dart`](lib/core/icons/app_icons.dart) |
| Responsive setup / fold layout | [`config.dart`](lib/core/responsiveness/responsive_config/config.dart), [`fold_aware_layout.dart`](lib/core/responsiveness/fold_aware_layout/fold_aware_layout.dart) |
| Screen entrance effects | [`core/animation/`](lib/core/animation/) |

## Startup and shared providers

The application is split into three clear responsibilities:

| File | Responsibility |
| --- | --- |
| [`main.dart`](lib/main.dart) | Initializes Flutter and starts `ResponsiveConfig(child: MyApp())`. No feature UI or repository setup lives here. |
| [`app.dart`](lib/app/app.dart) | Owns `MyApp`, `MaterialApp`, locale/delegates, theme switching, system bar styling, route observer, and the initial `DashboardScreen`. |
| [`app_providers.dart`](lib/app/app_providers.dart) | Creates the shared `ThemeCubit`, `PostsCubit`, `ProfileCategoriesCubit`, `CartCubit`, and `PostAnalyticsCubit`, using local repositories by default. |

```text
main()
  → ResponsiveConfig
    → MyApp
      → AppProviders
        → MaterialApp
          → DashboardScreen(initialTab: DashboardTab.home)
```

`MyApp` accepts `initialThemeMode`, `postsRepository`, `categoriesRepository`,
`cartRepository`, and `analyticsRepository` overrides for previews or later
integrations. `PostsCubit` starts its load when created, as do `CartCubit` and `ProfileCategoriesCubit`. `ThemeCubit` is
session state. Posts, categories, Cart, and analytics use their local adapters.
Notifications are scoped to Home, rather than registered in `AppProviders`.

One legacy analytics **export only** remains at
`features/post_analytics/presentation/domain/cubit/post_analytics_cubit.dart`.
Its implementation is in the canonical `presentation/cubit/` path. Use the
canonical path for new code. There is no dashboard compatibility page or second
dashboard view.

## Dashboard and navigation

The only dashboard screen is
[`pages/dashboard_screen.dart`](lib/features/dashboard/presentation/pages/dashboard_screen.dart).
Its tab list and native `PageView` are directly inside that file. The removed
`dashboard_pages.dart`, `dashboard_shell_view.dart`, and misspelled legacy
`dahboard_screen.dart` must not be recreated or imported.

| Tab index | Tab | Current destination |
| ---: | --- | --- |
| 0 | Home | `HomeScreen`: the new scrollable phone feed. |
| 1 | Cart | `CartScreen`: Cart and Checkout stages inside the existing dashboard tab. |
| 2 | Create (+) | Opens `CreatePostGalleryScreen` as a full-screen route. The PageView slot remains for stable swipe indexes. |
| 3 | Search | `SearchScreen`: results, suggestions, and the inline city picker. |
| 4 | Profile | `ProfileScreen`, or the optional `profilePage` supplied to the dashboard. |

`app/app.dart` explicitly starts the app on **Home**. The dashboard's own optional
constructor default is Profile; app startup does not rely on that default.

`DashboardScreen` owns/disposes its `PageController` and navigation Cubit. Taps
and swipes update the same selected tab. It retains entrance animations,
reduced-motion handling, and the shared bottom navigation with fold-aware layout.
Selecting Create opens its route without selecting a different dashboard tab.
A successful local publish closes the create routes and returns to **Profile**.

## Home screen

[`HomeScreen`](lib/features/home/presentation/pages/home_screen.dart) is one main
screen that imports UI widgets. It has no Home repository, Home Cubit, Home view
proxy, or backend layer. A lazy `ListView.builder` shows the HYWORK header and six
sample phone cards. The existing Home navigation icon opens this screen.

### Home widgets

| Widget / import target | Responsibility |
| --- | --- |
| [`home_notification_button.dart`](lib/features/home/presentation/widgets/home_notification_button/home_notification_button.dart) | Notification bell and unread count; opens the sample notification route. |
| [`home_feed_header.dart`](lib/features/home/presentation/widgets/home_feed_header/home_feed_header.dart) | Centered HYWORK wordmark. |
| [`home_product_card.dart`](lib/features/home/presentation/widgets/home_product_card/home_product_card.dart) | Composes image, engagement, details, price, and divider; owns local like/bookmark state. |
| [`home_product_image.dart`](lib/features/home/presentation/widgets/home_product_image/home_product_image.dart) | Network image, fixed photo backdrop, pre-order/discount badges, loading indicator, and retry. |
| [`home_engagement_bar.dart`](lib/features/home/presentation/widgets/home_engagement_bar/home_engagement_bar.dart) | Left-side rating, smaller client icons, and a right-aligned bookmark/comment/share/like/bag group; adapts for larger text. |
| [`home_metric.dart`](lib/features/home/presentation/widgets/home_metric/home_metric.dart) | One consistently styled icon/count and optional toggle callback. |
| [`home_product_details.dart`](lib/features/home/presentation/widgets/home_product_details/home_product_details.dart) | Right-aligned Persian phone title and mobile category. |
| [`home_product_price.dart`](lib/features/home/presentation/widgets/home_product_price/home_product_price.dart) | Sample current/original prices, currency label, and stock pill. |
| [`home_badge.dart`](lib/features/home/presentation/widgets/home_badge/home_badge.dart) | Shared pill shape used for pre-order, discount, and stock labels. |

### Where the Home image and values come from

The URL and title are explicitly declared in `HomeScreen.phoneImageUrl` and
`HomeScreen.phoneTitle`. The image is the green Google Pixel 9 front/back product
photo matching the supplied reference. It is fetched using `Image.network`, not
copied into app assets or obtained from Search data.

- Product image source: [Smarty product page](https://www.smarty.sk/google-pixel-9-12gb-128gb-wintergreen-4p159917).
- Network image URL: `https://doc.smarty.sk/pic/0f1e8c73d99d417ea73a3db313bcd924-600-600.webp`.
- Change that constant in `home_screen.dart` to replace the photo across this feed.
- Home image loading has an error/retry UI; web uses the HTML-image fallback
  strategy when normal image fetching is unavailable.
- The prices, stock, badges, rating, and engagement totals are **sample UI values**
  from the reference. They are not current market prices or server statistics.
- Like and bookmark update the individual card's local UI state. Their state is
  retained while scrolling that feed. The bag button adds the phone to the shared
  cart, merges quantities for the same product, and enforces the sample stock of two.
  Comments and share remain display elements. The engagement count is sample UI,
  while the navigation badge shows the actual number of cart lines.
- Local publishing updates the Profile grid, not these illustrative phone cards.

The main Home screen and each extracted Home widget remain below 150 lines.

## Cart and local checkout

[`CartScreen`](lib/features/cart/presentation/pages/cart_screen.dart) composes the
Cart and Checkout stages inside the dashboard tab; there is no separate payment
page. Cart, Order history, and Sales are the three list tabs.

### Actions and navigation

- The dashboard badge counts cart lines and updates after additions/removals.
- Tap a card to review that item in Checkout, or the bottom Checkout button to
  review all currently visible items. An active status filter limits that selection.
- Swipe a card left to remove it; the delete background and accessibility action
  expose the same removal operation.
- Tap the quantity pill to open the amount dialog. Cancel discards input; Done
  validates and applies it. Whole-unit products require integers; other units
  support two decimal places, with stock/positive quantity checks.
- The header menu filters by order status. It is not a clear-cart menu.
- Checkout shows selected cards, subtotal, discount, editable nonnegative charges,
  bank radios, and escrow explanation. Melli, Mellat, and Saman logos are bundled;
  Mellat is initially selected.
- Checkout Back returns to Cart; the Cart header Back returns to Home.
- Order history renders order snapshots if present in the loaded local data;
  Sales currently shows an empty state.

The current Checkout has **no payment-submit action or gateway route**. It does
not create a receipt, remove purchased items, charge a bank, or transfer escrow.
The order model/history widget can display existing saved snapshots, but the
current Cubit has no order-creation/payment method. `CartCubit.clear()` exists as
a controller action, without a visible clear-confirmation flow in this screen.

### Named Cart widgets

All paths below are under `features/cart/presentation/widgets/`, with one named
component folder and matching Dart file per row.

| Folder / widget | Responsibility |
| --- | --- |
| `cart_header` / `CartHeader` | Right-aligned stage title, Back, and optional trailing control. |
| `cart_tabs` / `CartTabs` | Cart, Order history, and Sales tabs. |
| `cart_status_menu` / `CartStatusMenu` | Header status filter menu. |
| `cart_status_filter` / `CartStatusFilter` | Active filter label and reset control. |
| `cart_items_list` / `CartItemsList` | Item list, swipe removal, amount editing, and Checkout entry. |
| `cart_item_card` / `CartItemCard` | Item information, pricing, image, and quantity control. |
| `cart_item_badge` / `CartItemBadge` | Item status badge. |
| `cart_item_image` / `CartItemImage` | Sample placeholder or added-product image with failure fallback. |
| `cart_quantity_button` / `CartQuantityButton` | Quantity/unit pill. |
| `cart_delete_background` / `CartDeleteBackground` | Swipe-to-remove background. |
| `cart_amount_dialog` / `CartAmountDialog` | Validated amount form, reusing the themed post-dialog shell and shared text field. |
| `cart_dialog_actions` / `CartDialogActions` | Persian Cancel/Done actions for amount dialogs. |
| `cart_checkout` / `CartCheckout` | Selected items, totals, bank choices, and escrow explanation. |
| `cart_section` / `CartSection` | Right-aligned section title and spacing. |
| `cart_payment_summary` / `CartPaymentSummary` | Exact totals and additional-charge entry. |
| `cart_payment_methods` / `CartPaymentMethods` | Bank radios and original-color SVG logos. |
| `cart_order_history` / `CartOrderHistory` | Expandable locally loaded order snapshots. |
| `cart_empty_state` / `CartEmptyState` | Cart/History/Sales empty messages. |
| `cart_storage_notice` / `CartStorageNotice` | Local storage failure/retry. |

### Data, amounts, and persistence

`CartCubit` is shared through `AppProviders`. `CartState` owns items, order
snapshots, selected checkout IDs, stage/tab, method, charges, and status filter.
Widgets call named actions; calculations and persistence stay outside layout.

- `domain/models/` contains `CartItem`, `CartOrder`, `CartOrderStatus`,
  `CartSnapshot`, and `PaymentMethod`.
- `domain/repositories/cart_repository.dart` defines the storage contract and an
  in-memory adapter. `data/local_cart_repository.dart` stores version 1
  `cart.json` using a temporary write and rename; the Cubit queues writes.
- `data/demo_cart_items.dart` supplies five first-launch fixtures with placeholder
  images. Saved empty carts stay empty on relaunch; fixtures are not reinserted.
- Home adds its sample phone title/network image and merges matching quantities,
  subject to stock. Its 13,000 toman unit price minus 1,000 discount gives 12,000.
- Quantities are integer hundredths (`1037` means `10.37` units). Unit prices are
  whole toman; computed money uses integer hundredths of a toman. The formatter
  accepts Latin/Persian/Arabic digits and displays Persian digits.
- Read failures preserve the existing file and block editing until retry. Write
  failures show a storage notice and allow retry.
- `core/localization/cart_strings.dart` holds Persian Cart copy. Amount sheets
  reuse the opposite-theme post-dialog shell. Regular surfaces/text use the app
  theme and fixed colors come from `AppColors`.
- `assets/banks/` contains the reusable bank SVGs and attribution/license files.
  App action icons use `AppIcons` and `AppIcon`.

The bottom navigation composes `DashboardNavItem`, `DashboardCartIcon`, and
`DashboardFoldLayout` from `dashboard/presentation/widgets/bottom_navbar/`.

## Search screen and city selection

The Search bottom-navigation icon opens
[`SearchScreen`](lib/features/search/presentation/page/search_screen/search_screen.dart).
It keeps feature state alive across tab changes and provides `SearchCubit`.
[`SearchView`](lib/features/search/presentation/page/search_screen/search_view.dart) owns the
text/focus controllers and named button handlers. This is the existing Search
composition; the Home feature does not add a matching view layer.

### Search widgets

| Widget / import target | Responsibility |
| --- | --- |
| [`search_header.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_header/search_header.dart) | Fixed query field, location button, and a visible Back control for open panels. |
| [`search_query_field.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_query_field/search_query_field.dart) | Uses the shared AppTextField with search styling, submit, and clear actions. |
| [`search_city_button.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_city_button/search_city_button.dart) | Location icon and selected city label; opens/closes the city-list panel. |
| [`search_city_list.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_city_list/search_city_list.dart) | Full-width scrollable Iranian city list with right-side radio circles. |
| [`search_content.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_content/search_content.dart) | Chooses the city list, suggestions, results grid, or empty state with ordinary if statements. |
| [`search_suggestions.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_suggestions/search_suggestions.dart) | Right-aligned service suggestions with circled search icons. |
| [`search_results_grid.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_results_grid/search_results_grid.dart) | Responsive service grid; new city/query results reset grid scroll position. |
| [`search_result_card.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_result_card/search_result_card.dart) | Service image, title, sample price, discount/pre-order badge, and post-detail entry. |
| [`search_empty_state.dart`](lib/features/search/presentation/widgets/search_screen_widgets/search_empty_state/search_empty_state.dart) | Localized empty message and a reset action. |

### Search interaction flow

1. Search starts with the sample query `لوله‌کش` and Tehran selected.
2. Tapping the field shows suggestions; typing updates the editing query.
3. Keyboard Search, the search icon, or a suggestion confirms a query and shows results.
4. The location icon shows the **full city picker beneath the same fixed header**,
   matching the supplied reference. It is not a dropdown, popup menu, or new route.
5. Tapping a city filters available sample services, updates its label, returns to
   the results grid, and starts the refreshed grid at the top. The Search tab stays selected.
6. The visible Back control closes suggestions/cities and restores the last
   confirmed query. System Back closes an active panel too.
7. The × inside the field clears only the editing text. It does not mean Close.
8. Tapping a result opens the existing `PostDetailScreen` with that service's title,
   city, price, and image. Back returns to Search.

`SearchState.query` is the editing text; `submittedQuery` is the last confirmed
query. `city` and `SearchPanel` select the location and visible content. Closing a
panel discards unsubmitted edits; it does not clear the confirmed results.

### Search sample data and locations

| File | Purpose |
| --- | --- |
| [`demo_search_posts.dart`](lib/features/search/data/demo_search_posts.dart) | Explicit sample entries: title, image path, price, optional badges, and available cities. |
| [`search_catalog.dart`](lib/features/search/data/search_catalog.dart) | Local matching/filtering and conversion into shared PostItem values. |
| [`search_strings.dart`](lib/core/localization/search_strings.dart) | Persian Search labels, 18 service suggestions, and 31 Iranian city names. |
| [`search_cubit.dart`](lib/features/search/presentation/cubit/search_cubit.dart) | Named actions for editing, submitting, city selection, opening/closing panels. |
| [`search_state.dart`](lib/features/search/presentation/cubit/search_state.dart) | Query, confirmed query, city, and visible panel. |

Search images are the existing bundled **`assets/img1.png`, `assets/img2.png`, and
`assets/img3.png`**. Each sample explicitly names its image; there is no image-path
calculation and no Search image download.

Filtering checks both the query and each sample's `cities` list. It does not
relabel every result as available everywhere. A city without matching samples
shows the empty state. The picker lists all 31 city names even where the demo has
no services. Edit the sample entries' city lists to change preview availability.

Persian/Arabic `ی`/`ي`, `ک`/`ك`, whitespace, and Persian half-spaces are normalized
for matching. No geolocation permission, GPS lookup, reverse geocoding, external
city API, or production service-search endpoint is used here.

## Profile screen

[`ProfileScreen`](lib/features/profile/presentation/page/profile_screen/profile_screen.dart)
is the Profile tab. Its widgets are under
[`profile_screen_widgets/`](lib/features/profile/presentation/widgets/profile_screen_widgets/),
with a named subfolder for each component: avatar, identity, statistics, category
chips, post grid/card, and header actions.

The grid reads the shared `PostsCubit` and `ProfileCategoriesCubit`: newly saved
posts appear first, and category chips filter by stable category ID. Publishing
returns to Profile and selects the new post's category. Tap a card to open details;
its three-dot menu can edit/delete posts present in this local Profile dataset,
including the seeded sample cards.

Header actions open chat, the theme menu, and the settings list. Profile settings
list UI is kept separately in
[`page/profile_settings_screen/`](lib/features/profile/presentation/page/profile_settings_screen/)
and [`profile_settings_screen_widgets/`](lib/features/profile/presentation/widgets/profile_settings_screen_widgets/).
The personal-information form is the separate `features/profile_settings` module,
not this list page.

## Settings list, profile edit, and locations

Profile header three dots → `ProfileSettingsScreen` → settings rows. The list has
seventeen entries under General. Labels currently render in Persian; the names
below identify the design entries for developers.

| Entry | Destination / status |
| --- | --- |
| Profile setting | [`ProfileEditScreen`](lib/features/profile_settings/presentation/pages/profile_edit_screen.dart) — separate personal-information form module. |
| Locations | [`LocationsScreen`](lib/features/locations/presentation/pages/locations_screen.dart) — map and label preview. |
| Wallet | [`WalletScreen`](lib/features/wallet/presentation/page/wallet_screen/wallet_screen.dart) — Wallet module. |
| Saved, Notifications, Trending, Insights, Scheduled content, Blocked, Comments, Language, Device permissions, Accessibility, Posts, My media, Tags & Keywords, Archive | List rows only; no destination callbacks yet. The working Notifications entry is the Home bell. |

The settings-list Back and check controls both close the route. The list does not
save account settings.

### Profile edit form

[`features/profile_settings/`](lib/features/profile_settings/) contains the form
screen and its own widgets: `ProfilePhotoPicker`, `ProfileEditFields`,
`ProfileEditField`, and `ProfileBirthField`. Fields cover first/last name,
nationality, username, email, birth date, gender, and bio. Gallery photo selection
uses `image_picker`; the selected bytes are only retained by the widget.

The birth picker uses Persian Material labels over `DateTime`; a Jalali calendar
conversion is not implemented. Gender is currently a text field. The shared
[`SettingsDetailHeader`](lib/shared/widgets/settings_detail_header/settings_detail_header.dart)
provides Back/Done. Done dismisses the form; it does not persist a profile or
change the Profile tab's sample identity/avatar.

### Locations preview

Widgets stay in [`locations/presentation/widgets/`](lib/features/locations/presentation/widgets/):
`LocationMapPreview`, `LocationLabelCard`, and `SavedLocationList`. The map initially
shows New Delhi to match the reference; the sample address text refers to London.
These are independent sample values, with no address lookup or GPS connection.

Users can add/select labels in this screen's state. Leaving the route discards
those changes. There is no saved-address repository or shared address book;
create-post/chat map selection are separate flows. OpenStreetMap tiles require
internet and retain attribution. The base map artwork does not change to a dark
tile style when switching app theme.

## Notifications

The Home header bell opens
[`NotificationsScreen`](lib/features/notifications/presentation/pages/notifications_screen.dart).
`HomeScreen` creates/disposes `NotificationsCubit` and passes the same instance to
the route, so row read state and the header badge agree while Home remains alive.
Opening the route clears its search query.

| Location | Responsibility |
| --- | --- |
| [`data/sample_notifications.dart`](lib/features/notifications/data/sample_notifications.dart) | Sample order and sale entries. |
| [`domain/models/app_notification.dart`](lib/features/notifications/domain/models/app_notification.dart) | Notification identity, title/body, time label, optional image URL, and unread count. |
| [`presentation/cubit/`](lib/features/notifications/presentation/cubit/) | Title/body filtering and marking a row read; no network or persistence. |
| [`presentation/widgets/`](lib/features/notifications/presentation/widgets/) | Named folders for header, search field, list, row tile, and avatar/unread badge. |
| [`home_notification_button.dart`](lib/features/home/presentation/widgets/home_notification_button/home_notification_button.dart) | Bell button and Home unread badge. |

Tapping an entry clears its unread count; it does not open an order/product.
Read state resets when the owning Home state is recreated. Sale avatars use a
network image with a fallback. Push delivery, notification permissions, OS
notifications, and backend read synchronization are not implemented.

## Wallet

Wallet is a UI-only module with sample data and a transaction model. Its folder
structure follows the requested screen grouping:

```text
wallet/
├── data/wallet_sample_data.dart
├── domain/models/wallet_transaction.dart
└── presentation/
    ├── page/
    │   ├── wallet_screen/wallet_screen.dart
    │   ├── top_up_screen/top_up_screen.dart
    │   ├── withdraw_screen/withdraw_screen.dart
    │   └── withdraw_summary_screen/withdraw_summary_screen.dart
    └── widgets/
        ├── wallet_screen_widgets/
        ├── top_up_screen_widgets/
        ├── withdraw_screen_widgets/
        └── withdraw_summary_screen_widgets/
```

| Widget group | Components / reuse |
| --- | --- |
| `wallet_screen_widgets` | Header, layered balance card/footer, action row/tile, transaction list/tile, and bottom button. Other Wallet screens import these same components. |
| `top_up_screen_widgets` | Payment methods, bank tile, and bank logo; logos reuse the shared `assets/banks/` assets. |
| `withdraw_screen_widgets` | Amount section/presets, text field, account section, and OTP fields. Top Up also reuses the amount section. |
| `withdraw_summary_screen_widgets` | Withdrawal illustration, summary details, and summary row. |

### Wallet navigation and behavior

1. Settings → Wallet shows the balance card, five action tiles, and Today/Yesterday transactions.
2. Top Up opens the amount/preset controls and bank radio options. Payment closes
   the preview back to Wallet.
3. Withdraw opens amount, account-number, and OTP UI. The OTP button starts a
   local countdown; it sends or validates no code.
4. Withdraw Done opens the summary preview. Summary Back returns to the form;
   Summary Done closes both routes and returns to Wallet.

Transfer, Request, and Payment on the main Wallet action row are display-only.
All monetary values, account examples, and transactions are samples from
[`wallet_sample_data.dart`](lib/features/wallet/data/wallet_sample_data.dart).
The summary still uses these samples rather than submitted form values. No wallet
repository, gateway, SMS service, balance mutation, or withdrawal request exists.

Persian Wallet copy and display-number formatting live in
[`wallet_strings.dart`](lib/core/localization/wallet_strings.dart).
[`WalletHeader`](lib/features/wallet/presentation/widgets/wallet_screen_widgets/wallet_header.dart)
right-aligns titles with 16 pixels of title spacing. Amount/account values keep
readable digit ordering. The artwork is
[`assets/wallet/withdrawal.png`](assets/wallet/withdrawal.png), a transparent raster
illustration; the same bank logos and icon system are used across the forms.

## Folder, import, and coding conventions

### Feature ownership

Keep code inside its existing feature and add only layers that are needed.
`data/` holds adapters or explicit sample data, `domain/` holds models/contracts
and validation, and `presentation/` holds pages, Cubits, helpers, and widgets.
A UI-only screen does not need an empty repository or Cubit just to fit a pattern.
Post categories and post editing belong to `features/posts`; there is no separate
category feature. Personal-information editing belongs to `features/profile_settings`.

### Page and widget grouping

Use the current screen grouping for Wallet, Search, and Profile:

```text
presentation/
├── page/
│   └── screen_name/
│       └── screen_name.dart
└── widgets/
    └── screen_name_widgets/
        └── component_name/
            └── component_name.dart
```

Search uses `page/search_screen/` and
`widgets/search_screen_widgets/<component_name>/`. Profile separates both pages
and their widgets into `profile_screen` / `profile_settings_screen` groups.
Wallet uses four screen widget groups with the Dart files directly inside each
group, as shown in its section. Reused Wallet widgets stay in their owning group;
do not copy them into every screen folder.

Other existing modules still use `presentation/pages/` and named component
folders directly below `widgets/`. Some older widgets, including the call preview
and `published_post_content.dart`, are flat files. The full tree is the reference
for actual paths; this documentation update does not move source files.

### Imports and readability

Use `package:nini/...` across features/project folders. Adjacent files can use
relative imports. Keep filenames/folders in `snake_case` and widget classes in
`UpperCamelCase`. For example:

```dart
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/features/search/presentation/page/search_screen/search_screen.dart';
import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_header/search_header.dart';
import 'package:nini/features/profile/presentation/page/profile_screen/profile_screen.dart';
import 'package:nini/features/wallet/presentation/page/wallet_screen/wallet_screen.dart';
```

- Compose screens from clearly named widgets; keep new UI files short and focused
  (aim for 150 lines or fewer). Some existing files are longer.
- Keep state/actions in the existing Cubit or screen owner; storage belongs in adapters.
- Reuse shared widgets and typed post models; add cross-feature UI to `shared/`
  only when multiple features need it.
- Add fixed colors to `AppColors` and brightness-dependent roles to `AppTheme`.
- Add labels to the matching localization catalog; keep IDs/JSON keys untranslated.
- Dispose controllers, focus nodes, timers, subscriptions, and owned Cubits.
- Use native `Navigator` routes, following the existing flow and route results.
- After moving files, update all imports and documentation; avoid duplicate screens
  and unnecessary compatibility exports.
- Keep the current UI-only workflow: do not recreate `test/` or add test files.
  Run additional checks only within the scope of the requested work.

## Shared colors and reusable widgets

### One color palette

[`AppColors`](lib/core/theme/app_colors.dart) is the shared source of fixed colors.
The color refactor preserved the existing shades and alpha values while replacing
scattered color literals throughout the theme, Home, Profile, Search, chat, calls,
post details, analytics, create-post widgets, and navigation.

The palette contains common black/white/transparent colors, light/dark surfaces
and outlines, notification/cart/stock/status indicators, analytics series, call
action/video-overlay colors, and attachment badges. `stockBadgeBackground` is the
pale stock pill added for the Home reference. `AppColors.red` is the explicit
red used for post/category delete actions; destructive actions should not use a
washed-out neutral button color. There is no separate AnalyticsColors palette.

```dart
import 'package:nini/core/theme/app_colors.dart';

// A fixed design color:
const badgeColor = AppColors.notificationBadge;

// Inside build(), for colors that follow the active theme:
final surface = Theme.of(context).colorScheme.surface;
final foreground = Theme.of(context).colorScheme.onSurface;
```

Use fixed colors for intentionally fixed artwork/overlays, such as the white
Home product-photo backdrop, red discount pill, and call action colors. Use
`colorScheme` roles for page surfaces, regular text/icons, and borders. Do not
scatter new `Color(0x...)` or `Colors.*` values through feature widgets.

### Shared UI entry points

| Widget/model | Import target and use |
| --- | --- |
| AppIcon | [`shared/widgets/app_icons/app_icon.dart`](lib/shared/widgets/app_icons/app_icon.dart): SVG/legacy PNG icons with inherited tint and optional selected background. |
| AppButton | [`shared/widgets/app_button/app_button.dart`](lib/shared/widgets/app_button/app_button.dart): primary, outlined, and text variants; loading/disabled state. |
| AppTextField | [`shared/widgets/app_textfield/app_text_field.dart`](lib/shared/widgets/app_textfield/app_text_field.dart): controllers, validation, icons, submit/tap callbacks, configurable direction. |
| AppLoader | [`shared/widgets/app_loader/app_loader.dart`](lib/shared/widgets/app_loader/app_loader.dart): shared progress indicator and optional label. |
| AppToast | [`shared/widgets/app_toast/app_toast.dart`](lib/shared/widgets/app_toast/app_toast.dart): localized success/error/info feedback. |
| PostMediaView | [`shared/widgets/post_media/post_media_view.dart`](lib/shared/widgets/post_media/post_media_view.dart): bundled asset images, owned local media, thumbnails, and placeholders. |
| SettingsDetailHeader | [`shared/widgets/settings_detail_header/settings_detail_header.dart`](lib/shared/widgets/settings_detail_header/settings_detail_header.dart): shared Back/Done header for Profile Edit and Locations. |
| PostItem / PostDetails / PostUnit | [`shared/models/post/`](lib/shared/models/post/): typed shared post identity, content, attributes, media, and units. |

`AppTextField` defaults to RTL and accepts explicit LTR fields. Photos are not
icon-tinted. Home uses AppIcon for every engagement icon, including filled selected-state
variants that retain the client heart/bookmark SVG path geometry.

## Light and dark mode

The theme logic lives in `lib/core/theme/`:

| File | Responsibility |
| --- | --- |
| [`app_colors.dart`](lib/core/theme/app_colors.dart) | Central fixed palette used throughout the app. |
| [`app_theme.dart`](lib/core/theme/app_theme.dart) | Builds `AppTheme.light` and `AppTheme.dark`: colors, typography, buttons, icons, menus, tooltips, app bars, and system bars. |
| [`theme_cubit.dart`](lib/core/theme/theme_cubit.dart) | Stores the current `ThemeMode` and exposes methods to change it. Uses the existing `flutter_bloc` dependency. |
| [`theme_mode_menu.dart`](lib/core/theme/theme_mode_menu.dart) | Sun/moon button in the profile header with Light, Dark, and System choices. Labels are Persian, matching the app. |

### Color rules

| Element | Light mode | Dark mode |
| --- | --- | --- |
| Main backgrounds | White (`#FFFFFF`) | Black (`#000000`) |
| Primary surface text, prices, counts, and chip labels | Black (`#000000`) | White (`#FFFFFF`) |
| Subdued labels and original prices | On-surface black with reduced alpha | On-surface white with reduced alpha |
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
Photos, red notification/discount badges, stock pills, and green avatar rings
retain their designed colors. Fixed photo-overlay badges use their own contrasting
foregrounds from AppColors.
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
button in the profile header lets users explicitly choose Light, Dark, or System.
An explicit choice overrides device brightness until System is selected again.

`AppProviders`, used by `MyApp`, provides one `ThemeCubit` above `MaterialApp`. A `BlocBuilder` connects its
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
  fixed palette values in `AppColors`, theme roles in `AppTheme`, and Persian copy
  in `AppStrings` or the existing feature string catalog.
- Treat `ThemeCubit.state` as a preference: System is resolved by `MaterialApp`.
  Use `Theme.of(context).brightness` when you need the actual rendered mode.

The Home phone feed keeps its supplied photo/stock/discount treatment. Its active
heart/bookmark use filled variants of the same client SVG shapes; the selected-background behavior above
still describes AppIcon-based navigation and existing post controls.

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

## Publishing and the shared post feed

Publish validates the form, shows the existing `AppButton` loading spinner, and
disables duplicate submissions, editing, and back/cancel while the save is in
progress. Failure keeps the draft and selected attachments intact, shows an
error, and re-enables Publish. Success returns a typed `PostItem` through details
→ gallery → dashboard, switches to Profile, and scrolls to the new first post.

| Component | Responsibility |
| --- | --- |
| `features/posts/domain/posts_repository.dart` | Storage interface, separate from screens and navigation. |
| `features/posts/data/local_posts_repository.dart` | Copies gallery/picked media to private app storage, writes the post snapshot, and reloads published posts. |
| `features/posts/presentation/cubit/posts_cubit.dart` | One shared feed above `MaterialApp`, plus load/publish/update/delete state and duplicate-save protection. |
| `features/posts/data/demo_posts.dart` / `profile_sample_posts.dart` | Sample definitions and conversion into editable Profile records, seeded once in local storage. |
| `shared/models/post/post_item.dart` and `post_media.dart` | Post identity, media, compatibility accessors, and JSON serialization. |
| `shared/models/post/post_details.dart` and `post_attributes.dart` | Typed caption, tags, address, schedule, features, stock/discount details, and legacy metadata compatibility. |
| `shared/widgets/post_media/post_media_view.dart` | Displays app-owned image files, video thumbnails when available, and named file/video placeholders. |
| `features/posts/presentation/widgets/published_post_content.dart` | Read-only rich caption, actual title/tags/address, and saved schedule metadata. |
| `features/post_detail/presentation/widgets/pricing/post_pricing.dart` | Shared single-post pricing block: saved sale price, struck-through original price when discounted, and the selected unit. |

The single-post page displays pricing below the engagement bar for both sample
and published posts. Prices use Persian digits, unit names use the existing
Persian labels, and the block follows the page's light/dark theme and RTL layout.
`PostDetails.unit` reads the unit already saved in draft metadata; existing posts
need no storage migration. `PostUnit` lives in `shared/models/post/post_unit.dart`
and is re-exported by create-post options so existing form imports still work.
Sample products explicitly use the piece unit. Missing prices and missing or
unknown legacy units are omitted rather than assigning invented values.

Published posts and media are stored under `nini_posts/` in the application
Documents directory (`path_provider` on other platforms; the iOS sandbox directly
on iOS, so an already-running app does not depend on new FFI assets to save). Media paths in `posts.json` are relative
so they survive changes to the app's Documents path. Selected original files are
copied, so temporary picker paths and later gallery permission changes do not
remove the published copy. Metadata is replaced atomically after copying media;
a failed save does not add a half-finished post. If a gallery preview-file export
fails, publishing tries the original image export before reporting failure. A damaged existing index is not
overwritten. The Profile post grid shows a retry action if saved posts fail to load.

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

The new HYWORK Home and Search catalogs remain separate demo UI. They do not
consume newly published posts; `ProfilePostGrid` is the current shared-post feed.

## Profile categories and post edit/delete

### Category selection and management

Profile's + opens
[`ProfileCategoriesScreen`](lib/features/posts/presentation/pages/profile_categories_screen.dart).
Rows expose selection, rename, and delete; the + action opens the add sheet.
Create/edit sheets share category action widgets and use the existing themed
post-dialog shell. Delete asks for confirmation and uses `AppColors.red`.

`ProfileCategoriesCubit` is shared above `MaterialApp`. The
[`ProfileCategoriesRepository`](lib/features/posts/domain/profile_categories_repository.dart)
contract provides `load`, `create`, `rename`, and `delete`; its current adapter is
[`LocalProfileCategoriesRepository`](lib/features/posts/data/local_profile_categories_repository.dart).
Stable IDs survive renames. Validation trims names, limits them to 50 characters,
and rejects blank/duplicate names and the reserved All label.

Create and Edit both compose
[`PostCategorySelector`](lib/features/posts/presentation/widgets/post_category_selector/post_category_selector.dart).
`PostDraft.profileCategoryId` / `PostItem.profileCategoryId` carry the selection.
This is independent of the Product/Services post type. All is a virtual filter,
and choosing no category leaves the post visible in All only.

Deleting a category deletes only that category record. Its posts and media remain
saved, with their missing category ID treated as unassigned. Those posts remain
visible under All, and deleting the selected category resets that filter.
Known default names are translated at display time; custom category text is not
automatically translated or restricted to Persian keyboard input.

### Owner menu and full editor

Post details checks the shared dataset before enabling owner actions. The left
three-dot menu is coordinated by
[`manage_post_actions.dart`](lib/features/posts/presentation/helpers/manage_post_actions.dart):
Edit pushes `EditPostScreen`; Delete opens a confirmation sheet and closes details
after successful deletion. Current ownership means membership in this device's
Profile dataset; there is no authenticated account check yet.

| Location | Responsibility |
| --- | --- |
| [`post_draft_mapper.dart`](lib/features/posts/presentation/helpers/post_draft_mapper.dart) | Rehydrates stored fields and base price so an existing discount is not applied twice. |
| [`edit_post_screen.dart`](lib/features/posts/presentation/pages/edit_post_screen.dart) | Owns form/controller lifecycle, save/cancel, rich-caption synchronization, and unsaved-change confirmation. |
| [`edit_post_form/`](lib/features/posts/presentation/widgets/edit_post_form/) and `post_editor_*` widget folders | Compose category, title, rich caption, media/alt text, prices/stock, type/unit/preparation, inventory, schedule, location, features, and tags. |
| [`post_editor_media_cubit.dart`](lib/features/posts/presentation/cubit/post_editor_media_cubit.dart) | Unsaved attachment retention, additions, removals, and replacements. |
| [`post_media_changes.dart`](lib/features/posts/domain/models/post_media_changes.dart) | Explicit retained paths and new attachments passed to the repository. |
| [`posts_cubit.dart`](lib/features/posts/presentation/cubit/posts_cubit.dart) | Shared load/save/delete state, busy protection, and error reporting. |
| [`local_post_media_store.dart`](lib/features/posts/data/local_post_media_store.dart) | Stages/copies new media and cleans up unused local media after a successful index update. |
| [`post_delete_sheet/`](lib/features/posts/presentation/widgets/post_delete_sheet/) / `post_delete_actions/` | Red delete confirmation; dismiss/duplicate actions are blocked while saving. |

Saving preserves the post ID, list position, and publication time. Details and
Profile rebuild from the updated record, including changed photos and caption.
Failure keeps the editor draft available for retry. Back/Cancel confirms discard
when changes are unsaved. Attachment changes do not delete bundled asset images.

### Editable sample posts and storage migration

`profile_sample_posts.dart` gives the existing Profile samples asset-backed
`PostMedia` and editable fields. `LocalPostsRepository` seeds these records when
creating the index and migrates version 1 indexes to version 2 while preserving
existing user posts. Version 2 saves the complete dataset, including samples;
samples are not appended on every load, so deleting a sample stays deleted.
Sample `publishedAt` remains null, including after an edit, to keep sample records
separate from real locally published analytics events.

`PostMedia.source` distinguishes `asset` from `local`; old serialized media defaults
to local. `PostMediaView` handles both sources. The repository writes the JSON
index atomically, preserves unreadable indexes, and only removes unused owned
files after a successful commit.

## Local storage and backend handoff

All paths below are relative to the app's Documents directory. iOS resolves the
sandbox Documents sibling of its temporary directory; other targets use
`path_provider`. These are device files, not repository source files.

| Data | Current implementation | Persisted location / lifetime |
| --- | --- | --- |
| Profile posts and owned media | `PostsRepository` → `LocalPostsRepository` | `nini_posts/posts.json`, version 2; per-post media folders under `nini_posts/`. |
| Profile categories | `ProfileCategoriesRepository` → `LocalProfileCategoriesRepository` | `nini_profile_categories/categories.json`, version 1. |
| Cart and existing order snapshots | `CartRepository` → `LocalCartRepository` | `cart.json`, version 1. |
| Post analytics events | `PostAnalyticsRepository` → `LocalPostAnalyticsRepository` | `post_analytics.json`, version 1. |
| Chat messages/block flags | `ChatMessagesRepository` → `InMemoryChatRepository` | Current repository instance/session; attachment copies use temporary local cache. |
| Theme | `ThemeCubit` | Session preference; system mode follows platform brightness. |
| Notifications | Home-owned `NotificationsCubit` | Home state lifetime; sample read/search state only. |
| Profile edit / Locations | Widget state/controllers | Route lifetime; no persistent account/profile/address store. |
| Wallet | Sample constants and widget state | No persisted financial data or operations. |

For a backend integration, inject post/category/cart/analytics adapters through
`MyApp` and `AppProviders`; keep network and serialization logic out of widgets.
`PostsRepository` explicitly exposes `load`, `publish`, `update`, and `delete`.
An authenticated adapter must enforce ownership for update/delete and preserve
stable post/category IDs. Category deletion must not cascade into post deletion.

Notifications, profile/account edits, saved locations, and Wallet still need real
data contracts and adapters. Their previews do not currently submit data. Chat
has service/repository interfaces for later integration, and calls use
`PreviewCallService` behind `CallService`; neither provides remote delivery.
Scheduling currently saves metadata without a background publishing worker.

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
The original imported collection contains **421 SVGs and 657 legacy PNGs**.
Home additionally uses two filled SVG state variants, for **423 runtime SVGs**
in total. The original 421 files and their manifest checksums remain unchanged.

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
| Profile header: theme menu | `vectors/environment/sun.svg` / `moon.svg` |
| Profile header: messages and post comments | `vectors/communication/chat.svg` |
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

Home additionally uses `AppIcons.shoppingBag` for the reference counter row.
The network phone image remains a normal photo and is not rendered through AppIcon.

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
      activity_tracking/       # Post view, watch-time and card impression tracking
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
  A card impression is recorded when at least 50% of a published post's card
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

`visibility_detector` supplies card visibility callbacks.
`PostImpressionTracker` accepts a source. Profile cards pass `profile`; Search
result cards pass `search`. Recording applies to published posts, while current
Search fixtures are sample posts. The new Home phone UI is not connected to that
tracker. The report retains home/search/profile/other channels for existing data.

## Persian text on the new screens

### Localization file map

| File in `lib/core/localization/` | Scope |
| --- | --- |
| [`app_strings.dart`](lib/core/localization/app_strings.dart) | Shared actions, create/gallery, post display, analytics, chat/calls, formatting, and legacy category display labels. |
| [`cart_strings.dart`](lib/core/localization/cart_strings.dart) | Cart, local checkout, preview receipts, validation/status/payment labels. |
| [`search_strings.dart`](lib/core/localization/search_strings.dart) | Search, service suggestions, and city names. |
| [`profile_post_strings.dart`](lib/core/localization/profile_post_strings.dart) | Profile categories, post edit/delete, default-category/unit labels, and error copy. |
| [`profile_settings_strings.dart`](lib/core/localization/profile_settings_strings.dart) | Settings-list section and entries. |
| [`profile_edit_strings.dart`](lib/core/localization/profile_edit_strings.dart) | Personal-information form labels and photo feedback. |
| [`location_strings.dart`](lib/core/localization/location_strings.dart) | Location preview, label/address samples, and map status. |
| [`notification_strings.dart`](lib/core/localization/notification_strings.dart) | Notification title/search, relative times, sample messages, and semantics. |
| [`wallet_strings.dart`](lib/core/localization/wallet_strings.dart) | Wallet titles, fields, banks, amount labels, Persian owner/sample formatting, and countdown text. |
| [`persian_feature.dart`](lib/core/localization/persian_feature.dart) | Scoped Persian locale and default right text alignment while preserving physical layout order. |

Static UI labels and known samples use Persian. User input, original filenames,
account/email values, internal IDs, and JSON keys keep their own content. Persian
locale does not force the keyboard language or translate custom English names.
Use explicit RTL text/right alignment for Persian, LTR where account/email digit
ordering needs it, and `AppStrings.persianDigits` for display numbers. Never store
translated display digits in IDs or serialized enum values.

Gallery selection, the create-post form, its option dialogs, publishing messages,
post analytics, chat, call previews, and attachment sheets use Persian copy from
`lib/core/localization/app_strings.dart`; Search also uses
`lib/core/localization/search_strings.dart`. New settings, Wallet, notifications,
Cart, and post-management screens use the feature catalogs above.
This includes buttons, hints, validation errors, tooltips, chart legends, period
menus, month/weekday labels, and numeric summaries. Add future UI labels there
and reference the matching string catalog in widgets instead of hard-coding English text.
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
English Product/Services categories also display their Persian labels on Profile
cards without rewriting saved records.

The global layout intentionally preserves the client design order with LTR
Directionality in `app.dart`. Persian text/fields and right-aligned components
apply RTL explicitly; do not globally mirror every image, tab, or chart axis.
The HYWORK wordmark and product model names may remain brand/model text.

## Chat, voice notes, and attachments

Open the Profile messages button, then choose a conversation. The feature lives in
`lib/features/chat/`, using the same `domain`, `data`, and `presentation` folders
as the other features. App startup remains separate in `main.dart` / `app/`. Shared client artwork is referenced
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

Call previews add no native plugins or permissions. Check native
microphone/camera behavior on target devices before shipping those integrations.

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

## Packages and platform configuration

Package constraints and asset registrations are authoritative in
[pubspec.yaml](pubspec.yaml); resolved versions are in `pubspec.lock`.

| Area | Packages used |
| --- | --- |
| State | `flutter_bloc` |
| Responsive/foldable layout | `flutter_screenutil`, `responsive_framework`, `foldable` |
| Vector icons / optional animation wrapper | `flutter_svg`, `rive` |
| Gallery and files | `photo_manager`, `photo_manager_image_provider`, `file_picker` |
| Rich text | `flutter_quill`, Flutter localization delegates |
| Maps | `flutter_map`, `latlong2`, `url_launcher` |
| Local storage and file paths | `path_provider`, `path` |
| Card impressions | `visibility_detector` |
| Voice and media | `record`, `just_audio`, `open_filex`, `image_picker` |
| In-app emoji | `emoji_picker_flutter` |
| Development declarations | `flutter_test` and `flutter_lints` remain in the manifest, although `test/` was removed. `shared_preferences` is currently a dev dependency. |

No new dependency was needed for the Home network image or the Search city list.
`Image.network` is part of Flutter; local Search images are bundled assets.

| Native file | Current configuration |
| --- | --- |
| [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) | Internet access, Android-version-specific media access, selected photos/videos, and microphone permission. |
| [`ios/Runner/Info.plist`](ios/Runner/Info.plist) | Persian photo-library, microphone, and camera usage descriptions. HTTPS images/tiles do not require an ATS bypass. |
| [`DebugProfile.entitlements`](macos/Runner/DebugProfile.entitlements) | Sandbox/JIT/debug-server entries plus outgoing network-client access for image/tile requests. |
| [`Release.entitlements`](macos/Runner/Release.entitlements) | Sandbox and outgoing network-client access. |

The Search city picker requests **no location permission**. Create-post and chat
location sharing use a manually chosen map pin, not GPS detection. A selected
city in Search is not the same feature as the address map.

## Verification

This README was refreshed against the current source tree on **2 November 2026**.
The documentation check covers the complete `lib/` file inventory and local links.
No tests, analyzer, build, or device run were performed for this README-only update.

The `test/` directory and its preview helpers were removed at the user's request.
Earlier passing-test counts and commands are not a verification record for this
checkout. Do not recreate that folder as part of UI work.

For a separately requested static check, use `dart analyze lib` (or
`flutter analyze` for project-wide analysis). Static analysis does not establish
rendered design fidelity or native plugin behavior. Device review remains needed
for target platforms, including both themes, narrow widths, keyboards, media
permissions, recording/playback, and map loading.

## Common changes and troubleshooting

| Change / symptom | Where to look or what to do |
| --- | --- |
| Change the initial app tab | `lib/app/app.dart`, `DashboardScreen(initialTab: ...)`. |
| Change the Home phone image/title | Constants in `features/home/presentation/pages/home_screen.dart`. |
| Change Home sample prices, stock, or discount appearance | `home_product_price/` and `home_product_image/` widgets; these are sample UI values. |
| Change the Home brand | `home_feed_header/home_feed_header.dart`. |
| Add a city or suggestion | `core/localization/search_strings.dart`; sample availability must also be added to the corresponding entries in `demo_search_posts.dart`. |
| Change Search results/images/prices | `features/search/data/demo_search_posts.dart`; matching is in `search_catalog.dart`. |
| Close Search without submitting edits | Use the visible Back control; the × only clears editing text. |
| Location icon behavior | It shows the full radio-list panel beneath the Search header. Keep that design; city selection returns results in place. |
| See saved/newly published posts | Use the Profile tab, not the illustrative Home phone feed. |
| Open chat or change theme | Use the Profile header controls. |
| Change colors | Add/edit `AppColors` for fixed palette values; edit `AppTheme` for semantic theme roles. |
| Import fails after moving a widget | Use the actual screen/component group in the source tree and update every importing file. |
| A Home photo does not load | Check internet and the configured URL, then Retry. Native configuration changes need a rebuild. |
| Newly declared assets/plugins do not appear | Run `flutter pub get`, stop the app, and rebuild. |
| Gallery shows only selected items | The OS granted limited access; use Select more or Settings rather than assuming full access. |
| Local save fails | Keep the draft, retry, and inspect the local-storage error; saving locally does not upload to a server. |
| Voice/video preview does not connect | Calling is UI-only; a real CallService/RTC integration is still pending. |

## Repository workflow

The reviewed local checkout uses branch `main`, with upstream `client/main`.
Its configured remotes are:

| Remote | URL / purpose |
| --- | --- |
| `client` | `https://github.com/mojtaba-zarabi/mobile-hywork.git` — client repository. |
| `origin` | `https://github.com/zeeeshaan/nini.git` — existing personal repository. |

These aliases belong to this checkout. A fresh clone of the client repository
normally calls that repository `origin`. Check before pushing:

```sh
git status --short --branch
git remote -v
```

After reviewing and committing the intended changes, this checkout can explicitly
send its current commit to the client main branch with:

```sh
git push client HEAD:main
```

This README describes the working tree. It does not mean uncommitted UI changes
have been uploaded, deployed, or merged. Documentation updates do not stage,
commit, or push source changes automatically.
