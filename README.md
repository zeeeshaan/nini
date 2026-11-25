# HYWORK (mobile)

Flutter marketplace client for **HYWORK**. Dart package name: **`nini`**.  
Remote: [hywork-team/mobile-hywork](https://github.com/hywork-team/mobile-hywork).

Authenticated flows talk to the HYWORK HTTP API. Cart, chat, calls, teams, wallet, payment, and notifications remain mostly local / demo.

---

## Run

```bash
# Pass the API base URL at build/run time (required)
flutter run --dart-define=API_BASE_URL=http://35.154.187.106/api
```

Default base used in this project: `http://35.154.187.106/api` (see `api_config/api.json`).  
OpenAPI reference: `http://35.154.187.106/api/docs/openapi-user.json`.

```bash
flutter pub get
flutter analyze --no-pub
```

Version: `1.0.0+1` · Dart `^3.13.3`

---

## Startup

```text
lib/main.dart
  → ResponsiveConfig
    → MyApp → AppProviders
      → MaterialApp
        → LoginScreen        (no session)
        → SplashScreen       (token present → restore via GET auth/me → Dashboard)
```

- Token: `SecureTokenStore` (`flutter_secure_storage`)
- Session: `SessionCubit` + `AuthRepository.restoreSession()`
- Dashboard tabs: **Home · Cart · Create · Search · Profile**

---

## Repository layout

```text
lib/
  main.dart                 App entry
  app/
    app.dart                MaterialApp, theme, locale, home routing
    app_providers.dart      ApiClient, repos, Cubits (session-scoped account data)
  core/
    config/app_config/      API_BASE_URL from --dart-define
    network/api_client/     Dio wrapper (JSON + multipart, Bearer auth)
    security/
      secure_token/         Auth token persistence
      account_storage/      Per-user local files
    constants/              AppAssets, AppIcons (incl. Flaticon cart URLs)
    theme/                  Colors, text styles, AppTheme, ThemeCubit
    localization/           App strings (EN / FA)
    media/                  Image / document compressors
    permissions/            Location permission helper
    animations/             Screen / staggered / Rive helpers
    responsiveness/         ScreenUtil + ResponsiveFramework
  shared/
    models/post/            PostItem, seller, media, unit, attributes
    widgets/                Buttons, icons, toast, skeletons, calendar, logo
    cubits/                 Shared countdown / map tiles
  features/                 Feature modules (data · domain · presentation)
assets/                     Icons, fonts, branding, bank logos, etc.
api_config/api.json         Documented API base URL
docs/                       Extra notes (e.g. API testing status)
tool/                       Icon import scripts
android/ · ios/             Native projects
```

Each feature under `lib/features/<name>/` usually follows:

| Folder | Role |
|--------|------|
| `data/` | API or local repositories |
| `domain/` | Models, contracts, validation |
| `presentation/pages/` | Screens |
| `presentation/cubit/` | State |
| `presentation/widgets/` | UI pieces |
| `presentation/helpers/` | Navigation / action helpers |

---

## Features and important files

| Feature | Purpose | Key places |
|---------|---------|------------|
| **login** | Phone/email OTP request, session restore/logout | `login/data/auth_repo.dart`, `login/presentation/pages/login_screen.dart`, `session_cubit.dart` |
| **otp_verification** | Verify OTP, save Bearer token | `otp_verification/data/otp_verification_repo.dart`, `…/pages/otp_verification_screen.dart` |
| **splash** | Post-auth bootstrap → dashboard | `splash/presentation/pages/splash_screen.dart` |
| **dashboard** | Bottom nav shell | `dashboard/presentation/pages/dashboard_screen.dart`, `…/widgets/bottom_navbar/` |
| **home** | Public feed (`scope=all`) + engagement UI | `home/presentation/pages/home_screen.dart`, `posts/presentation/cubit/backend_posts_cubit.dart` |
| **posts** | Backend posts API (create/edit/delete/social), local posts fallback | `posts/data/api_posts_repository.dart`, `local_posts_repository.dart`, Cubits under `posts/presentation/cubit/` |
| **create_post** | Gallery → details form; **edit uses the same details screen** | `create_post/presentation/pages/create_post_gallery_screen.dart`, `create_post_details_screen.dart`, `helpers/attachments_from_post_media.dart`, `data/api_categories_repository.dart` |
| **post_detail** | Post detail, owner ⋮ menu (edit/delete/resubmit) | `post_detail/presentation/pages/post_detail_screen.dart`, `posts/presentation/widgets/actions/` |
| **search** | Backend search + suggestions | `search/presentation/pages/search_screen.dart` + `ApiPostsRepository.search*` |
| **profile** | Own profile grid + public seller profile, follow | `profile/presentation/pages/profile_screen.dart`, `seller_profile_screen.dart`, `data/api_public_profile_repository.dart` |
| **profile_settings** | Edit profile, My Posts, categories, settings hubs | `api_user_profile_repository.dart`, `profile_edit_screen.dart`, `posts_screen.dart` |
| **saved_posts** | Saved list (API when authenticated) | `saved_posts/…` + `ApiPostsRepository.loadSaved` / `setSaved` |
| **cart** | Local cart / orders | `cart/data/local_cart_repository.dart`, `cart_screen.dart` |
| **payment** | Demo gateway, invoice, dispute | `payment/presentation/pages/` |
| **order_cancellation** | Cancel order UI | `order_cancellation/…` |
| **provider_invoice** | Provider invoice UI | `provider_invoice/…` |
| **chat** | In-memory inbox / conversation | `chat/data/in_memory_chat_repository.dart` |
| **calls** | Preview call UI (no real media) | `calls/…` |
| **team** | Session-only teams | `team/data/in_memory_teams_repository.dart` |
| **wallet** | Sample wallet / withdraw UI | `wallet/…` |
| **locations** | Location labels UI | `locations/…` |
| **notifications** | Derived from local order timelines | `notifications/…` |
| **post_analytics** | Local analytics store | `post_analytics/…` |

### Create vs edit posts

- **Create** and **edit** share `CreatePostDetailsScreen` (prefill + Save when `editPost` / `backendPost` is set).
- `EditPostScreen` routes into that shared UI.
- Owner actions on profile / detail use backend manage paths (edit → shared form, delete, resubmit for `changes_requested`).

### Icons

- Cart (home/detail): Flaticon bag `808583` via `AppIcons` + `CachedNetworkImage` (`lib/shared/widgets/app_icons/app_icon.dart`).
- Bottom nav cart: Flaticon outline `54895` (`dashboard_cart_icon.dart`).
- Fallbacks under `assets/icons/interface/`.

---

## Network layer

**File:** `lib/core/network/api_client/api_client.dart`

| Method | Use |
|--------|-----|
| `get` / `getPublic` | JSON GET (optional Bearer) |
| `post` | JSON POST |
| `postMultipart` | Multipart upload (`file` field) |
| `patch` / `put` / `delete` | Authenticated mutations |

Headers: `Accept: application/json`, `X-Client: mobile`, `Authorization: Bearer <token>` when authenticated.  
Responses expected as `{ "success": bool, "data": ... }`.

Config: `lib/core/config/app_config/app_config.dart` → `String.fromEnvironment('API_BASE_URL')`.

---

## Integrated APIs

Base path below is relative to `API_BASE_URL` (e.g. `…/api`).

### Auth & session

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `POST` | `auth/request-otp` | `AuthRepository` | Body `{ phone }` or `{ email }`. Phone normalized to `09xxxxxxxxx`. |
| `POST` | `auth/verify-otp` | `OtpVerificationRepository` | Body identity + 6-digit `code`. On success saves `data.token` in secure storage. |
| `GET` | `auth/me` | `AuthRepository`, `ApiUserProfileRepository` | Confirms session / loads current user. 401 → clear token. |
| `POST` | `auth/logout` | `AuthRepository` | Revokes server session, then deletes local token. |

### Profile (me)

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `PATCH` | `users/me` | `ApiUserProfileRepository` | Diff of editable fields: name, username, email, nationality, businessType, bio, city, birthDate, gender, avatarUrl. Confirms via response + optional `auth/me` read-back. |
| `POST` | `uploads?purpose=avatar` | `ApiUserProfileRepository` | Multipart avatar; returned URL written as `avatarUrl` on PATCH. |

### Public users & social

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `GET` | `users/profile/{username}` | `ApiPublicProfileRepository` | Public seller profile (optional auth for `isFollowing` / `isMe`). |
| `GET` | `users/{id}/posts` | same | Paginated published posts for a user (`categoryId`, `page`, `limit`). |
| `GET` | `users/{id}/categories` | same | Public profile categories. |
| `GET` | `users/{id}/followers` | same | Paginated followers. |
| `GET` | `users/{id}/following` | same | Paginated following. |
| `POST` | `users/{id}/follow` | same | Follow user; returns updated profile. |
| `DELETE` | `users/{id}/follow` | same | Unfollow; expects `isFollowing: false`. |

### Profile categories (owner)

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `GET` | `users/me/categories` | `ApiProfileCategoriesRepository` | Load own categories. |
| `POST` | `users/me/categories` | same | Create `{ name }`. |
| `PATCH` | `users/me/categories/{id}` | same | Rename. |
| `DELETE` | `users/me/categories/{id}` | same | Delete; may return `postsMoved`. |
| `PUT` | `users/me/categories/order` | same | Body `{ ids: [...] }` reorder. |

### Catalogue categories

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `GET` | `categories` | `ApiCategoriesRepository` | Public product/service category keys for create-post. |

### Uploads & posts

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `POST` | `uploads?purpose=post` | `ApiPostsRepository` | Multipart image for post; SHA-256 checked; URL list attached to create/edit. |
| `POST` | `posts` | same | Create product/service from draft (type, category, title, description, price, discount, stock/unit, schedule, tags, features, location, images). |
| `GET` | `posts/mine` | same | Owner list (`status`, `page`, `limit`, `categoryId`). Powers My Posts + own profile grid (includes pending/revision/rejected). |
| `GET` | `posts/{id}` | same | Detail; public published, or owner-visible non-published. |
| `PATCH` | `posts/{id}` | same | Partial edit of touched fields + optional image rewrite. |
| `DELETE` | `posts/{id}` | same | Soft-delete owned post; expects `deleted: true`. |
| `POST` | `posts/{id}/resubmit` | same | Resubmit after `changes_requested`. |

### Feed, search, explore

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `GET` | `feed?scope=all&page&limit` | `ApiPostsRepository.loadFeed` | Home feed (all scopes). Cached briefly; enrich via detail for stock/unit when needed. |
| `GET` | `search?q&type=posts&page&limit` | `search` | Post search; returns posts + optional `searchId` / `understood`. |
| `GET` | `explore` | `explore` | Filtered browse (category, postType, price, stock, rating, tag, sort). |
| `GET` | `search/suggestions?q` | `searchSuggestions` | Suggestion strings. |
| `GET` | `search/popular` | `popularSearches` | Popular queries. |
| `GET` | `search/trending` | `trendingSearches` | Trending queries. |
| `POST` | `search/log` | `logSearchClick` | Logs click `{ searchId, event: click, postId, position }`. |

### Engagement

| Method | Endpoint | Client | How it works |
|--------|----------|--------|--------------|
| `POST` / `DELETE` | `posts/{id}/like` | `setLike` | Toggle like; returns `isLiked` + `likes` count. |
| `POST` / `DELETE` | `posts/{id}/save` | `setSaved` | Toggle save. |
| `GET` | `users/me/saved` | `loadSaved` | Paginated saved posts. |
| `GET` | `posts/{id}/comments` | `loadComments` | Comments (`parentId`, page, limit); auth optional. |
| `POST` | `posts/{id}/comments` | `createComment` | Body `{ text, parentId? }` (max 1000 runes). |
| `DELETE` | `comments/{id}` | `deleteComment` | Owner delete; may return updated `commentsCount`. |

### API client wiring

Registered in `lib/app/app_providers.dart`:

- `ApiClient`
- `AuthRepository` / `OtpVerificationRepository`
- `ApiUserProfileRepository` (when session authenticated)
- `ApiPublicProfileRepository`
- `ApiCategoriesRepository`
- `ApiPostsRepository` (backend posts / feed / social)
- `ApiProfileCategoriesRepository`

Local fallbacks still exist for cart, chat, teams, and some settings screens that are not API-backed yet.

---

## What is still local / demo

| Area | Status |
|------|--------|
| Cart & order history | Local JSON / demo seed |
| Payment gateway | Demo completion only |
| Chat & calls | In-memory / preview |
| Teams | Session-only |
| Wallet | Sample data + forms |
| Push notifications | Not integrated |
| Locations address book | Screen-local |

---

## Auth flow (summary)

1. User enters phone or email → `POST auth/request-otp`
2. Enter 6-digit code → `POST auth/verify-otp` → store Bearer token
3. Cold start → `GET auth/me` → if OK, open splash → dashboard
4. Logout → `POST auth/logout` → clear secure token → login

---

## Post lifecycle (backend)

```text
Create (POST posts) → pending_review → published
                      ↘ changes_requested → edit (PATCH) → resubmit (POST …/resubmit)
                      ↘ rejected (owner can still view from profile grid)
Owner can DELETE while manageable.
```

Home feed and search only show **published** posts. Own profile grid also shows pending / changes_requested / rejected via `posts/mine`.

---

## Related docs

- `docs/api_testing_status.md` — Postman verification notes for early auth/profile/upload checks
- `api_config/api.json` — documented `API_BASE_URL`
