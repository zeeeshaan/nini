# HYWORK API → UI guide

How each integrated API **fetches data**, moves it through **repositories / Cubits**, and **appears on screen**.

Base URL comes from `--dart-define=API_BASE_URL` (see `api_config/api.json`).  
HTTP client: `lib/core/network/api_client/api_client.dart` (Dio).  
Wiring: `lib/app/app_providers.dart`.

Typical chain:

```text
UI action / screen open
  → Cubit / Bloc / screen helper
    → Repository (Api*)
      → ApiClient (GET/POST/PATCH/DELETE/multipart)
        → JSON { success, data }
    → Cubit emits state
  → BlocBuilder / watch rebuilds widgets
```

---

## 1. Auth & session

### Request OTP

| | |
|--|--|
| **API** | `POST auth/request-otp` body `{ phone }` or `{ email }` |
| **Repo** | `AuthRepository.requestOtp` / `requestEmailOtp` |
| **State** | `AuthBloc` (`OtpRequested` / `EmailOtpRequested`) |
| **UI** | `LoginScreen` — phone or email field → Continue |

**Flow**

1. User submits identifier on `LoginScreen`.
2. `AuthBloc` calls repository; on success emits `OtpRequestAccepted` / `EmailOtpRequestAccepted`.
3. Listener navigates to `OtpVerificationScreen` with phone or email.
4. Toast for email OTP sent.

### Verify OTP

| | |
|--|--|
| **API** | `POST auth/verify-otp` body identity + `code` (6 digits) |
| **Repo** | `OtpVerificationRepository` → saves `data.token` in `SecureTokenStore` |
| **State** | `OtpVerificationCubit` then `SessionCubit.restore()` |
| **UI** | `OtpVerificationScreen` pin input → Verify |

**Flow**

1. User enters OTP → cubit verifies → token stored.
2. Screen calls `SessionCubit.restore()` → `GET auth/me`.
3. On authenticated session, app leaves login and opens splash → dashboard.

### Restore session / splash

| | |
|--|--|
| **API** | `GET auth/me` with Bearer token |
| **Repo** | `AuthRepository.restoreSession` |
| **State** | `SessionCubit` (`authenticated` + `userId`, or `unauthenticated`) |
| **UI** | Cold start: `MyApp` → Login if no session, else `SplashScreen` |

**Flow**

1. Splash listens to `SessionCubit` and calls `restore()`.
2. Valid `auth/me` → dashboard. 401 → clear token → login. Error → retry UI on splash.

### Logout

| | |
|--|--|
| **API** | `POST auth/logout` then delete local token |
| **Repo** | `AuthRepository.logout` |
| **UI** | Profile settings logout → returns to `LoginScreen` |

---

## 2. Current user profile

### Load profile

| | |
|--|--|
| **API** | `GET auth/me` |
| **Repo** | `ApiUserProfileRepository.load` |
| **State** | `UserProfileCubit` → `UserProfileState.profile` |
| **UI** | Profile tab header, edit screen, seller chip on own posts |

**Flow**

1. After auth, providers create `ApiUserProfileRepository` + `UserProfileCubit..load()`.
2. Maps API user → `UserProfile` (name, username, bio, city, gender, avatar, …).
3. `ProfileScreen` / dashboard watch cubit for avatar, name, business type.

### Save profile / avatar

| | |
|--|--|
| **API** | `POST uploads?purpose=avatar` (optional) then `PATCH users/me` |
| **Repo** | `ApiUserProfileRepository.save` |
| **State** | `UserProfileCubit.save` → updates `profile` or error toast |
| **UI** | `ProfileEditScreen` — fields + photo picker → Save |

**Flow**

1. Diff editable fields against last loaded profile.
2. Local photo → compress → multipart upload → `avatarUrl` in PATCH body.
3. Confirm fields from PATCH response; for avatar/birthDate/businessType also re-read `auth/me`.
4. UI shows saved profile or field-level “not confirmed” error.

---

## 3. Home feed

| | |
|--|--|
| **API** | `GET feed?scope=all&page=&limit=` |
| **Repo** | `ApiPostsRepository.loadFeed` / `loadFeedEnriched` |
| **State** | `FeedCubit` (`BackendPostsState`: posts, loading, hasMore, error) |
| **UI** | `HomeScreen` → `HomePublishedPostCard` list |

**Flow**

1. Home tab becomes active → `FeedCubit.refresh()`.
2. Repo calls feed; maps each card with `backendPostFromJson` → `PostItem`.
3. Optional enrichment: detail fetch fills stock/unit when PostCard omits them.
4. `BlocBuilder<FeedCubit>` builds:
   - skeletons while loading empty
   - cards for each `PostItem`
   - pull-to-refresh → `refreshFromServer`
   - near-bottom scroll → `loadMore`
5. Tap card → post detail (see §6). Like/save icons use `PostLikesCubit` / `SavedPostsCubit`.

---

## 4. Search

| | |
|--|--|
| **APIs** | `GET search?q=&type=posts&page=&limit=` · `GET search/suggestions` · `GET search/popular` · `GET search/trending` · `POST search/log` · `GET explore` (filters) |
| **Repo** | `ApiPostsRepository` |
| **State** | `SearchCubit` (query panel) + screen-local `BackendPostsCubit` for results |
| **UI** | `SearchScreen` / `SearchView` / `SearchContent` / `SearchResultsGrid` |

**Flow**

1. Opening search loads popular + trending chips via repo → chip taps set query.
2. Typing loads suggestions → `SearchSuggestions` list.
3. Submitting query → `BackendPostsCubit.refresh` with `repository.search(query:)`.
4. Results grid shows post thumbnails/titles; empty → `SearchEmptyState`.
5. Opening a result calls `logSearchClick` with `searchId` + position (fire-and-forget).
6. City panel is UI-only (not a backend people search).

---

## 5. Create & edit posts

### Catalogue categories (create form)

| | |
|--|--|
| **API** | `GET categories` |
| **Repo** | `ApiCategoriesRepository` |
| **State** | `PostCategoriesCubit` |
| **UI** | Category picker on `CreatePostDetailsScreen` |

### Upload images + create

| | |
|--|--|
| **API** | `POST uploads?purpose=post` (per image) then `POST posts` |
| **Repo** | `ApiPostsRepository` create path |
| **UI** | Gallery → `CreatePostDetailsScreen` → Publish |

**Flow**

1. `CreatePostGalleryScreen` picks media → opens details with attachments.
2. Form binds `CreatePostCubit` (`PostDraft`): type, title, caption, price, stock/unit, discount, tags, location, schedule, profile category.
3. Publish validates → uploads images (multipart, hash check) → `POST posts` with URLs + fields.
4. Success toast; `FeedCubit` / `OwnPostsCubit` refresh so home and profile grid update.

### Edit (same UI as create)

| | |
|--|--|
| **API** | `GET posts/{id}` (load) · `POST uploads?purpose=post` (new images) · `PATCH posts/{id}` |
| **Repo** | `loadEditablePost` / `updateEditablePost` |
| **UI** | `BackendEditPostScreen` → `CreatePostDetailsScreen` (edit mode, Save) |

**Flow**

1. Owner ⋮ → Edit → load editable post; draft + remote media prefilled (`attachments_from_post_media`).
2. Save diffs touched fields; uploads only new images; PATCH changes.
3. Pop updated `PostItem`; refresh feed/own posts; toast “Post changes saved.”

### Delete / resubmit

| | |
|--|--|
| **API** | `DELETE posts/{id}` · `POST posts/{id}/resubmit` |
| **Helper** | `manage_post_actions.dart` |
| **UI** | Owner actions sheet on detail / profile grid |

Delete confirmation sheet → API → remove from `FeedCubit` / `OwnPostsCubit`.  
Resubmit only when `backendStatus == changes_requested`.

---

## 6. Post detail

| | |
|--|--|
| **API** | `GET posts/{id}` |
| **Repo** | `ApiPostsRepository.loadDetail` |
| **State** | `PostDetailCubit` |
| **UI** | `PostDetailScreen` (media, price, seller, engagement, comments) |

**Flow**

1. Open from home/search/profile with `PostItem` id.
2. Cubit `loadDetail` → full `PostItem` (owner can see pending/revision/rejected).
3. Loading / error / retry in `BlocBuilder`.
4. Owner + `allowOwnerActions` → ⋮ menu (edit / delete / resubmit) without changing layout.

### Likes

| | |
|--|--|
| **API** | `POST` / `DELETE posts/{id}/like` |
| **State** | `PostLikesCubit` |
| **UI** | Heart on home card and detail |

Optimistic UI when possible; confirms with `isLiked` + `likes` count from API. Can reconcile via `loadDetail`.

### Save / unsave

| | |
|--|--|
| **API** | `POST` / `DELETE posts/{id}/save` · `GET users/me/saved` |
| **State** | `SavedPostsCubit` |
| **UI** | Bookmark on cards/detail · `SavedPostsScreen` grid |

Toggle calls `setSaved`. Saved screen paginates `loadSaved` → grid; remove unsaves and drops the tile.

### Comments

| | |
|--|--|
| **API** | `GET posts/{id}/comments` · `POST posts/{id}/comments` · `DELETE comments/{id}` |
| **State** | `PostDetailCubit` comment list / count |
| **UI** | Comments sheet on detail |

Load page of comments (optional `parentId` for replies). Submit adds to list. Delete updates count when API returns `commentsCount`.

---

## 7. Own profile posts & My Posts

### Profile grid (owner)

| | |
|--|--|
| **API** | `GET posts/mine` via `loadOwnProfilePosts` |
| **State** | `OwnPostsCubit` |
| **UI** | `ProfileScreen` → `ProfilePostGrid` |

Shows published **and** pending / changes_requested / rejected for the owner only. Category filter uses `categoryId`. Tap → detail with owner menu.

### My Posts settings

| | |
|--|--|
| **API** | `GET posts/mine` (status filters / pages) |
| **UI** | `PostsScreen` in profile settings |

Loads pages directly from repository; lists status, supports manage actions, refreshes feed/own cubits after mutations.

---

## 8. Public seller profile & follow

| | |
|--|--|
| **APIs** | `GET users/profile/{username}` · `GET users/{id}/posts` · `GET users/{id}/categories` · `GET users/{id}/followers|following` · `POST|DELETE users/{id}/follow` |
| **Repo** | `ApiPublicProfileRepository` |
| **State** | `SellerProfileCubit` |
| **UI** | `SellerProfileScreen` (header, follow button, category chips, post grid, people lists) |

**Flow**

1. Open from seller name/avatar → cubit loads profile by username.
2. Header shows avatar, name, bio, counts from API.
3. Follow / Unfollow → POST/DELETE follow → updates `isFollowing` and counts in state.
4. Posts tab paginates `users/{id}/posts` into grid (published only).
5. Categories from `users/{id}/categories`. Followers/following sheets use people list endpoints.

---

## 9. Profile categories (owner)

| | |
|--|--|
| **APIs** | `GET|POST users/me/categories` · `PATCH|DELETE users/me/categories/{id}` · `PUT users/me/categories/order` |
| **Repo** | `ApiProfileCategoriesRepository` |
| **State** | `ProfileCategoriesCubit` |
| **UI** | `ProfileCategoriesScreen` + category field on create/edit post |

Load on session; create/rename/delete/reorder update list in place. Create-post validates selected `profileCategoryId` against this cubit before publish.

---

## 10. Explore (related to search)

| | |
|--|--|
| **API** | `GET explore` with filters (category, postType, price, stock, rating, tag, sort, page, limit) |
| **Repo** | `ApiPostsRepository.explore` |
| **UI** | Available through search/browse paths that call explore with filters |

Same post envelope as feed; results mapped to `PostItem` and shown in result grids like search.

---

## UI mapping cheat sheet

| Screen | Primary API data | State object |
|--------|------------------|--------------|
| `LoginScreen` | request-otp | `AuthBloc` |
| `OtpVerificationScreen` | verify-otp + auth/me | `OtpVerificationCubit` + `SessionCubit` |
| `SplashScreen` | auth/me | `SessionCubit` |
| `HomeScreen` | feed | `FeedCubit` |
| `SearchScreen` | search / suggestions / popular / trending | `SearchCubit` + `BackendPostsCubit` |
| `CreatePostDetailsScreen` | categories, uploads, posts POST/PATCH | draft cubits + repo |
| `PostDetailScreen` | posts/{id}, like, save, comments | `PostDetailCubit`, likes, saved |
| `ProfileScreen` | auth/me + posts/mine | `UserProfileCubit`, `OwnPostsCubit` |
| `ProfileEditScreen` | auth/me, uploads avatar, users/me | `UserProfileCubit` |
| `PostsScreen` | posts/mine | Future/local page state |
| `SellerProfileScreen` | users/profile, posts, follow | `SellerProfileCubit` |
| `SavedPostsScreen` | users/me/saved | `SavedPostsCubit` |
| `ProfileCategoriesScreen` | users/me/categories* | `ProfileCategoriesCubit` |

---

## Response → UI model

Backend cards/details are normalized by `backendPostFromJson` in `api_posts_repository.dart` into shared `PostItem` (`lib/shared/models/post/`).

Used by home cards, search results, profile grids, detail, and saved list so widgets stay the same whether the source is feed, search, or mine.

Important metadata flags for UI:

- `metadata['backend'] == true` → use API manage/like/save paths  
- `metadata['backendStatus']` → pending_review / changes_requested / rejected / published (owner menus & badges)

---

## Not API-backed (local / demo UI only)

Cart, payment gateway, chat, calls, teams, wallet, locations address book, and notification push do **not** use these endpoints. They keep using local or in-memory repositories and are outside this document’s fetch→UI chains.

---

## Quick debug tips

1. No feed/search/profile posts → confirm `--dart-define=API_BASE_URL` and that session is authenticated (`SessionCubit`).
2. 401 anywhere → token cleared / session expired → login again.
3. Create succeeds but home empty → check post status (`pending_review` is owner-only until published).
4. Edit/delete missing on profile → post must be backend (`metadata['backend']`) and screen must pass owner actions (`allowOwnerActions`).
