# Noir Player

 **Noir Player** is a feature-rich Flutter music player with cloud synchronization that demonstrates:
 - Firebase Authentication with email/password login
 - Cloud-based playlist management with Firestore
 - Real-time playlist synchronization across devices
 - Background playback support with audio service
 - Querying the device's media library using **`on_audio_query`**
 - **Music discovery with Last.fm and YouTube integration**
 - **Online music streaming and downloading**
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
- [🌐 Music Discovery](#-music-discovery)
- [☁️ Cloud Features](#-cloud-features)
- [🧭 Workflow](#-workflow)
- [🛠️ Architecture Details](#-architecture-details)
- [📦 Dependencies](#-dependencies)
- [🔒 Security](#-security)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 📦 Overview

Noir Player is a modern, cross-platform Flutter music player that combines local audio playback with cloud-based playlist management:

1. **User Authentication** - Secure Firebase email/password authentication
2. **Cloud Playlists** - Create, manage, and sync playlists across devices via Firestore
3. **Local Audio Library** - Access all audio files from your device
4. **Music Discovery** - Discover trending tracks and search for new music online
5. **Online Streaming** - Stream music directly from YouTube via API integration
6. **Music Downloads** - Download discovered tracks to your device library
7. **Background Playback** - Music continues playing when app is backgrounded
8. **Real-time Sync** - Playlist changes sync instantly across all your devices
9. **Adaptive Theming** - Choose between System Default, Light, or Dark mode
10. **Beautiful UI** - Modern design with smooth animations and transitions

---

## ✨ Features

### 🎵 Music Playback
- **Local Library Access** - Browse all songs, albums, and artists on your device
- **Background Playback** - Continue listening while using other apps
- **Queue Management** - Play songs from playlists with full queue control
- **Album Artwork** - Display beautiful album art for all tracks

### 🌐 Music Discovery
- **Trending Tracks** - Discover popular music from Last.fm API
- **Search Music** - Search for any track across Last.fm's vast database
- **Online Streaming** - Stream discovered tracks directly via YouTube
- **Download Music** - Download tracks as MP3 files to your device
- **Album Artwork** - Fetch high-quality album art from Last.fm
- **Progress Tracking** - Real-time download progress indicators

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
│   │   ├── playlist_model.dart          # Playlist data model
│   │   └── discovered_track.dart        # Discovered track model
│   ├── services/
│   │   ├── audio_handler.dart           # Background audio service
│   │   ├── auth_service.dart            # Firebase Authentication
│   │   ├── playlist_service.dart        # Firestore playlist operations
│   │   └── music_discovery_service.dart # Music discovery & download
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
│   ├── discover/
│   │   └── discover_screen.dart         # Music discovery & streaming
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

## 🌐 Music Discovery

### Overview
The Music Discovery feature allows users to explore, stream, and download music from online sources using Last.fm and YouTube APIs.

### Features
- **Trending Music**: Browse trending tracks from Last.fm (country-specific)
- **Search**: Search for any track across Last.fm's extensive database
- **Stream Online**: Play discovered tracks directly via YouTube integration
- **Download**: Save tracks as MP3 files to your device's music library
- **Album Art**: Automatically fetch high-quality album artwork

### How It Works

#### 1. Discover Trending Tracks
1. Navigate to the "Discover" tab in the bottom navigation
2. Browse trending tracks from Last.fm
3. View track names, artists, and album artwork

#### 2. Search for Music
1. Tap the search bar in the Discover screen
2. Enter song name, artist, or keywords
3. View search results with album art

#### 3. Stream Music
1. Tap the play button on any discovered track
2. The app fetches the YouTube video ID
3. Extracts the audio stream URL
4. Plays the track using the built-in audio player
5. Use pause/play controls to manage playback

#### 4. Download Tracks
1. Tap the download button on any track
2. Watch real-time progress indicator
3. Track is saved to `NoirPlayerDownloads` folder
4. Access downloaded tracks from your device's music library

### API Integration

#### Last.fm API
- **Purpose**: Fetch trending tracks, search music, retrieve album artwork
- **Endpoints Used**:
  - `geo.gettoptracks` - Get trending tracks by country
  - `track.search` - Search for tracks
  - `track.getInfo` - Get track details and album art

#### YouTube API
- **Purpose**: Find YouTube videos for discovered tracks
- **Endpoint**: `youtube/v3/search` - Search for music videos

#### RapidAPI (YouTube to MP3)
- **Purpose**: Convert YouTube videos to MP3 format
- **Service**: `yt-mp3.p.rapidapi.com` - Get downloadable MP3 URLs

### Data Flow
```
User Action → Last.fm API → Track Info + Album Art
           ↓
    YouTube API → Video ID
           ↓
    RapidAPI → MP3 Stream URL
           ↓
    Stream/Download → Audio Player / Device Storage
```

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
| 8 | Discover music | Browse/search trending tracks → Stream/Download |
| 9 | Change theme | Settings → Select System/Light/Dark |
| 10 | Logout | Settings → Logout → Login screen |

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

#### MusicDiscoveryService (`music_discovery_service.dart`)
```dart
class MusicDiscoveryService {
  // Discovery
  Future<List<DiscoveredTrack>> fetchTrendingTracks();
  Future<List<DiscoveredTrack>> searchTracks(String query);
  Future<String> fetchAlbumArt(String track, String artist);
  
  // Streaming & Download
  Future<String> fetchYoutubeVideoId(String trackName, String artistName);
  Future<String?> getDownloadUrl(String videoId);
  Future<String?> saveFile(String url, String filename, {Function(int, int)? onProgress});
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
| `http`              | HTTP requests for APIs                  | ^1.1.0    |
| `dio`               | Advanced HTTP client for downloads      | ^5.2.0    |
| `path_provider`     | File system paths                       | ^2.1.2    |
| `media_store_plus`  | Save files to Android MediaStore        | ^0.1.3    |
| `youtube_explode_dart`| YouTube data extraction               | ^2.0.0    |
| `audioplayers`      | Additional audio playback               | ^6.5.1    |
| `flutter_downloader`| Download manager                        | ^1.11.2   |
| `flutter_inappwebview`| In-app web view                       | ^6.0.0    |
| `youtube_player_flutter`| YouTube player widget             | ^9.1.3    |

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

- [x] Music discovery and streaming
- [x] Download tracks from online sources
- [ ] iOS support
- [x] Add discovered tracks to playlists
- [ ] Playlist sharing between users
- [ ] Offline mode with local caching
- [ ] Music recommendations based on listening history
- [ ] Equalizer controls
- [ ] Sleep timer
- [ ] Lyrics support

---

> **Enjoy your music with Noir Player - Your personal cloud music player!** 🎵✨