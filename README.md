# TradeHub

TradeHub is a Flutter + Firebase peer-to-peer marketplace app where users can list items, discover products, chat with sellers in real time, and review each other after interactions.

This repository contains a full mobile project foundation with Firebase integration, Riverpod state management, GoRouter navigation, offline cache support, chat notifications, and marketplace-ready UI flows.

## Highlights

- Authentication (Email/Password)
- Marketplace listing feed with categories and shimmer loading
- Listing create/edit/detail flows with image upload to Firebase Storage
- Real-time in-app chat (Firestore-based)
- User profile with ratings and reviews
- Search with debouncing, filters, and recent searches cache
- Offline listing cache using Hive + connectivity awareness
- Bottom navigation with unread chat badge
- Firestore security rules included

## Tech Stack

- Flutter (Material)
- Firebase:
	- Firebase Auth
	- Cloud Firestore
	- Firebase Storage
	- Firebase Messaging
- Riverpod (`flutter_riverpod`)
- GoRouter (`go_router`)
- Hive (`hive`, `hive_flutter`)
- `cached_network_image`, `image_picker`, `connectivity_plus`, `timeago`, `intl`, `uuid`, `shimmer`

## Project Structure

```text
lib/
	core/
		constants/
		router/
		theme/
	models/
	providers/
	screens/
		auth/
		home/
		listing/
		chat/
		profile/
		search/
		orders/
	services/
	firebase_options.dart
	main.dart
```

## Implemented Modules

### 1) Authentication

- Splash auth-state check and redirect
- Login + Register screens with validation and loading/error handling
- User document creation in Firestore on registration

### 2) Home + Listings

- Category chips and listing grid
- Listing cards with image, title, price, seller, and relative time
- Pull-to-refresh and shimmer loading
- Offline mode banner and cached listings fallback

### 3) Listings CRUD

- Create listing with up to 5 images
- Edit listing with sold toggle
- Listing detail with seller card and chat CTA
- Owner controls for edit/delete

### 4) Search & Filters

- Debounced title search (`lowercaseTitle`)
- Filters: category, price range, sort order
- Recent searches saved in Hive (max 10)

### 5) Chat System

- Chat list with unread count
- Chat screen with real-time messages
- Mark messages as read
- Firebase Cloud Function trigger for FCM message notifications

### 6) Profile & Reviews

- User profile with avatar, rating, review count
- Tabs for active listings, sold listings, and reviews received
- Leave review bottom sheet with star rating and optional comment

## Firebase Setup

1. Create Firebase project.
2. Add Android app with package name:

```text
com.example.tradehub
```

3. Place `google-services.json` in:

```text
android/app/google-services.json
```

4. Enable services:
- Authentication (Email/Password)
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging

5. Deploy rules from this repo:

```bash
firebase deploy --only firestore:rules
```

## Run Locally

```bash
flutter pub get
flutter analyze
flutter run
```

## Cloud Functions (Optional)

The repository includes a Firestore trigger for new chat messages:

```text
functions/index.js
```

Deploy with:

```bash
firebase deploy --only functions
```

## Security Rules

Rules are included in:

```text
firestore.rules
```

Current policy includes:
- Users: only owner can update/delete
- Listings: only seller can modify
- Chats: only participants can access
- Reviews: read all, write for authenticated users

## Notes

- Google Sign-In is intentionally not implemented in this build.
- Payments are intentionally excluded.

## Author

Built for MAD Internal Practical Exam.