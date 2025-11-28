# Noir Player

 **Noir Player** is a feature-rich Flutter music player with cloud synchronization that demonstrates:
 - Firebase Authentication with email/password login
 - Cloud-based playlist management with Firestore
 - Real-time playlist synchronization across devices
 - Background playback support with audio service
 - Querying the device's media library using **`on_audio_query`**
 - Adaptive theming (System Default, Light, Dark modes)
 - Beautiful, modern UI with smooth animations

---

## Table of Contents
- [📦 Overview](#-overview)
- [✨ Features](#-features)
- [📁 Project Structure](#-project-structure)
- [🚀 Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Firebase Setup](#firebase-setup)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [🔐 Authentication](#-authentication)
- [☁️ Cloud Features](#-cloud-features)
- [🧭 Workflow](#-workflow)
- [🛠️ Architecture Details](#-architecture-details)
- [📦 Dependencies](#-dependencies)
- [� Security](#-security)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 📦 Overview

Noir Player is a modern, cross-platform Flutter music player that combines local audio playback with cloud-based playlist management:

1. **User Authentication** - Secure Firebase email/password authentication
2. **Cloud Playlists** - Create, manage, and sync playlists across devices via Firestore
3. **Local Audio Library** - Access all audio files from your device
4. **Background Playback** - Music continues playing when app is backgrounded
5. **Real-time Sync** - Playlist changes sync instantly across all your devices
6. **Adaptive Theming** - Choose between System Default, Light, or Dark mode
7. **Beautiful UI** - Modern design with smooth animations and transitions

---

## ✨ Features

### 🎵 Music Playback
- **Local Library Access** - Browse all songs, albums, and artists on your device
- **Background Playback** - Continue listening while using other apps
- **Queue Management** - Play songs from playlists with full queue control
- **Album Artwork** - Display beautiful album art for all tracks

### ☁️ Cloud Integration
- **Firebase Authentication** - Secure user accounts with email/password
- **Cloud Playlists** - Store playlists in Firestore for access anywhere
- **Real-time Sync** - Changes sync instantly across all devices
- **Automatic Migration** - Local playlists migrate to cloud on first login
- **Favorites Playlist** - Default playlist created for every user

### 🎨 User Experience
- **Adaptive Theming** - System Default, Light, and Dark modes
- **Smooth Animations** - Polished transitions and micro-interactions
- **Intuitive Navigation** - Easy-to-use drawer and tab-based interface
- **Search & Filter** - Quickly find songs in your library

### 🔐 Account Management
- **User Registration** - Create account with email/password
- **Secure Login** - Firebase Authentication integration
- **Logout** - Sign out from settings with confirmation dialog
- **Session Persistence** - Stay logged in across app restarts

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── models/
│   │   └── playlist_model.dart          # Playlist data model
│   ├── services/
│   │   ├── audio_handler.dart           # Background audio service
│   │   ├── auth_service.dart            # Firebase Authentication
│   │   └── playlist_service.dart        # Firestore playlist operations
│   └── theme/
│       └── app_theme.dart               # Light & Dark themes
├── screens/
│   ├── auth/
│   │   ├── auth_wrapper.dart            # Auth state management
│   │   ├── login_screen.dart            # User login
│   │   └── signup_screen.dart           # User registration
│   ├── home/
│   │   └── home_screen.dart             # Main navigation
│   ├── library/
│   │   ├── tabs/
│   │   │   ├── albums_tab.dart          # Albums view
│   │   │   ├── artists_tab.dart         # Artists view
│   │   │   ├── playlists_tab.dart       # Playlists view (Firebase)
│   │   │   └── songs_tab.dart           # Songs view (Firebase)
│   │   └── library_screen.dart          # Tab container
│   ├── player/
│   │   └── player_screen.dart           # Now playing screen
│   ├── playlists/
│   │   ├── playlists_screen.dart        # Playlist grid (Firebase)
│   │   └── playlist_songs_screen.dart   # Playlist details
│   ├── albums/
│   │   └── album_songs_screen.dart      # Album details
│   ├── artist/
│   │   └── artist_songs_screen.dart     # Artist details
│   └── settings/
│       └── settings_screen.dart         # Theme & logout
└── firebase_options.dart                # Firebase configuration
```

---

## 🚀 Getting Started

### Prerequisites

| Platform | Requirement                       |
|----------|-----------------------------------|
| Flutter  | SDK ≥ 3.9.0                       |
| Android  | Android 6.0+ (API level 23+)      |
| Firebase | Active Firebase project           |

- Install **Flutter SDK**:
  ```bash
  flutter --version
  ```
- **Android Permissions**: `READ_EXTERNAL_STORAGE` (handled by `on_audio_query`)

### Firebase Setup

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one

2. **Enable Services**:
   - Enable **Authentication** → Email/Password provider
   - Enable **Cloud Firestore** database

3. **Add Android App**:
   - Register your Android app with package name
   - Download `google-services.json`
   - Place in `android/app/` directory

4. **Configure FlutterFire**:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

5. **Firestore Security Rules**:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/playlists/{playlistId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Installation

```bash
git clone https://github.com/your-username/noir_player.git
cd noir_player
flutter pub get
```

### Running the App

```bash
# Android
flutter run -d android

# Release build
flutter build apk --release
```

> On first launch, create an account or login. The app will request permission to read your device's music library.

---

## 🔐 Authentication

### Sign Up
1. Open the app
2. Tap "Sign Up" on login screen
3. Enter email and password
4. Account created → Local playlists migrate to cloud
5. Default "Favorites" playlist created

### Login
1. Enter email and password
2. Tap "Sign In"
3. Access your cloud playlists from any device

### Logout
1. Open Settings from drawer
2. Tap "Logout" button
3. Confirm in dialog
4. Redirected to login screen

---

## ☁️ Cloud Features

### Playlist Management
- **Create Playlists**: Tap + button in Playlists tab
- **Add Songs**: Long-press any song → Select playlist
- **Remove Songs**: Long-press song in playlist → Confirm removal
- **Delete Playlists**: Long-press playlist card (except Favorites)

### Real-time Synchronization
- Changes sync instantly across all logged-in devices
- Add a song on your phone → See it immediately on tablet
- No manual refresh needed

### Data Structure (Firestore)
```
/users/{userId}/playlists/{playlistId}
  ├─ name: "My Playlist"
  ├─ isFavourite: false
  ├─ createdAt: timestamp
  └─ songs: [
      {
        id: 123,
        title: "Song Name",
        artist: "Artist Name",
        data: "/path/to/file",
        duration: 240000
      }
    ]
```

---

## 🧭 Workflow

### High-level Flow

```
┌──────────────────┐
│   App Launch     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Firebase Init    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     No      ┌──────────────────┐
│  Auth Check      │────────────▶│  Login Screen    │
└────────┬─────────┘             └────────┬─────────┘
         │ Yes                            │
         ▼                                ▼
┌──────────────────┐             ┌──────────────────┐
│  Home Screen     │◀────────────│  Sign Up         │
└────────┬─────────┘             └──────────────────┘
         │
         ▼
┌──────────────────┐
│  Library Tabs    │
│  (Songs/Albums/  │
│   Playlists)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Player Screen   │
│  (Now Playing)   │
└──────────────────┘
```

### User Journey

| Step | Action | Result |
|------|--------|--------|
| 1 | Launch app | Firebase initializes → Auth check |
| 2 | Login/Signup | User authenticated → Home screen |
| 3 | Grant permissions | Access to device music library |
| 4 | Browse library | View songs, albums, artists, playlists |
| 5 | Create playlist | Saved to Firestore → Syncs to cloud |
| 6 | Add songs | Long-press → Select playlist → Added |
| 7 | Play song | Background audio starts → Player screen |
| 8 | Change theme | Settings → Select System/Light/Dark |
| 9 | Logout | Settings → Logout → Login screen |

---

## 🛠️ Architecture Details

### Services

#### AuthService (`auth_service.dart`)
```dart
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  // Methods
  Future<UserCredential> signUp({required String email, required String password});
  Future<UserCredential> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}
```

#### PlaylistService (`playlist_service.dart`)
```dart
class PlaylistService {
  // CRUD Operations
  Future<void> createPlaylist({required String name, bool isFavourite = false});
  Stream<List<PlaylistModel>> getPlaylistsStream();
  Future<void> updatePlaylist({required String playlistId, required PlaylistModel playlist});
  Future<void> deletePlaylist(String playlistId);
  
  // Song Management
  Future<void> addSongToPlaylist({required String playlistId, required PlaylistSong song});
  Future<void> removeSongFromPlaylist({required String playlistId, required PlaylistSong song});
  
  // Migration
  Future<void> migrateLocalPlaylistsToFirebase();
  Future<void> initializeDefaultPlaylists();
}
```

#### AudioHandler (`audio_handler.dart`)
```dart
class AudioPlayerHandler extends BaseAudioHandler {
  // Playback control
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  
  // Queue management
  void setQueue(List<PlaylistSong> songs);
  Future<void> playSongAt(int index);
}
```

---

## 📦 Dependencies

| Package             | Purpose                                 | Version   |
|---------------------|-----------------------------------------|-----------|
| `flutter`           | SDK                                     | ≥ 3.9.0   |
| `firebase_core`     | Firebase initialization                 | ^4.2.1    |
| `firebase_auth`     | User authentication                     | ^6.1.2    |
| `cloud_firestore`   | Cloud database                          | ^6.1.0    |
| `just_audio`        | Audio playback                          | ^0.10.4   |
| `audio_service`     | Background audio                        | ^0.18.18  |
| `on_audio_query`    | Device music library                    | ^2.9.0    |
| `permission_handler`| Storage permissions                     | ^12.0.1   |
| `provider`          | State management                        | ^6.1.2    |
| `shared_preferences`| Local storage                           | ^2.5.3    |
| `audio_session`     | Audio session management                | ^0.2.2    |
| `rxdart`            | Reactive streams                        | ^0.27.7   |

> All packages are declared in [`pubspec.yaml`](pubspec.yaml).

---

## 🔒 Security

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own playlists
    match /users/{userId}/playlists/{playlistId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Best Practices
- ✅ User data isolated by UID
- ✅ Authentication required for all operations
- ✅ Passwords hashed by Firebase Auth
- ✅ HTTPS encryption for all data transfer
- ✅ No sensitive data stored locally

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please open an issue first to discuss major changes.

---

## 📄 License

MIT © 2024 Noir Player.  
See [LICENSE](LICENSE) for details.

---

## 🎯 Roadmap

- [ ] iOS support
- [ ] Playlist sharing between users
- [ ] Offline mode with local caching
- [ ] Music recommendations
- [ ] Equalizer controls
- [ ] Sleep timer
- [ ] Lyrics support

---

> **Enjoy your music with Noir Player - Your personal cloud music player!** 🎵✨