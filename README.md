# Noir Player

> **Noir Player** is a lightweight Flutter music player that demonstrates how to:
> - Initialise the Android audio service with background playback support  
> - Query the device’s media library using **`on_audio_query`**  
> - Play, pause, stop and show the current media item in a dedicated “Now Playing” screen  
> - Keep the UI responsive with `StreamBuilder`s  

> The project is a good starting point if you want to build a full‑featured music app or add your own custom playback logic.

---

## Table of Contents
- [📦 Overview](#-overview)
- [✨ Features](#-features)
- [📁 Project Structure](#-project-structure)
- [🚀 Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [🧭 Workflow](#-workflow)
  - [High‑level Flow Diagram](#high‑level-flow-diagram)
  - [Step‑by‑Step Walk‑through](#step‑by‑step-walk‑through)
- [🛠️ Architecture Details](#-architecture-details)
  - [`main.dart`](#maineditor)
  - [`library_screen.dart`](#librariescreen)
  - [`audio_handler.dart`](#audiohandler)
  - [`player_screen.dart`](#playerscreen)
- [📦 Dependencies](#-dependencies)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 📦 Overview

Noir Player is a small, cross‑platform Flutter app that:

1. **Loads all local audio files** from the device’s library.  
2. **Shows them in a tabbed library** (`All`, `Albums`, `Artists`, …).  
3. **Initialises a background audio service** (so playback keeps going while the app is backgrounded).  
4. **Plays a selected track** and navigates to a “Now Playing” screen that displays title, artist, album art and playback controls.

---

## ✨ Features

| Feature | File | How it works |
|---------|------|--------------|
| **Home Screen** | `home_screen.dart` | Simple drawer → `LibraryScreen` |
| **Tab‑based Library** | `library_screen.dart` | Uses `QueryArtworkWidget` & `OnAudioQuery` |
| **Audio Service** | `audio_handler.dart` | Wraps `audio_service` & `just_audio` |
| **Now Playing UI** | `player_screen.dart` | Consumes `audioHandler.mediaItem` & `audioHandler.playbackState` |
| **Background playback** | `audio_service` + `just_audio` | Keeps the music playing when the user leaves the app or locks the device |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   └── services/
│       └── audio_handler.dart
│   └── theme/
│       └── app_theme.dart
├── screens/
│   ├── home/
│   │   └── home_screen.dart
│   ├── library/
│   │   └── tabs/
│   │       └── albums_tab.dart
│   │       └── artists_tab.dart
│   │       └── playlists_tab.dart
│   │       └── songs_tab.dart
│   │   └── library_screen.dart
│   ├── player/
│   │   └── player_screen.dart
│   ├── playlists/
│   │   └── playlists_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   └── query_artwork_widget.dart
└── ...


```

> **Note**: The `lib/core/services/audio_handler.dart` file contains the core of the audio service (initialisation, play, pause, stop, media item updates).

---

## 🚀 Getting Started

### Prerequisites

| Platform | Requirement |
|----------|-------------|
| Android | Flutter SDK ≥ 2.18, Android 6.0+ |

- Make sure you have a recent version of **Flutter** installed:
  ```bash
  flutter --version
  ```
- For Android you’ll need the **READ_EXTERNAL_STORAGE** permission in `AndroidManifest.xml`.  
  Noir Player already includes the permission request flow via `on_audio_query`.

### Installation

```bash
git clone https://github.com/your‑username/noir_player.git
cd noir_player
flutter pub get
```

### Running the App

```bash
# Android
flutter run -d android

> On first launch, the app will request permission to read the device’s music library.  
> Grant the permission and the library will populate automatically.

---

## 🧭 Workflow

### High‑level Flow Diagram

```
┌──────────────────┐
│   Noir Player UI  │
│ (main.dart)       │
└────────┬──────────┘
         │ init
         ▼
┌──────────────────────┐
│ AudioServiceManager  │
│ (audio_handler.dart) │
└────────┬────────────┘
         │ start
         ▼
┌─────────────────────┐
│   Query Audio Files  │
│ (on_audio_query)     │
└───────┬──────────────┘
        │ fetch list
        ▼
┌──────────────────────┐
│   LibraryScreen       │
│ (library_screen.dart) │
└───────┬───────────────┘
        │ tab navigation
        ▼
┌───────────────────────┐
│  PlayerScreen          │
│ (player_screen.dart)   │
└───────────────────────┘
```

> Each arrow represents a *stream* or *event* (e.g., `audioHandler.mediaItem`, `audioHandler.playbackState`).  
> The UI listens to these streams and updates automatically.

### Step‑by‑Step Walk‑through

| # | User Action | App Reaction | Code Path |
|---|-------------|--------------|-----------|
| 1 | Launch app | `main.dart` → `initAudioService()` → `LibraryScreen` | `main.dart` |
| 2 | Open drawer → tap “Library” | `LibraryScreen` is pushed onto the Navigator stack | `home_screen.dart` |
| 3 | `LibraryScreen` appears | Tabs load (All / Artists / Albums). Each tab fetches tracks via `on_audio_query` and shows a list | `library_screen.dart` |
| 4 | Tap a song | `audioHandler.play(Song)` is called, which: <br>• Updates `MediaItem` stream <br>• Calls `JustAudio.setFilePath()` <br>• Starts playback | `audio_handler.dart` |
| 5 | UI updates | `StreamBuilder<MediaItem?>` on `PlayerScreen` shows title/artist/album art | `player_screen.dart` |
| 6 | Play/Pause button | `audioHandler.play()` / `audioHandler.pause()` toggles playback state | `player_screen.dart` |
| 7 | Stop/Back button | `audioHandler.stop()` & `Navigator.pop()` | `player_screen.dart` |
| 8 | Close app | Background audio continues due to `audio_service` configuration | `audio_handler.dart` |

---

## 🧱 Architecture Details

### `main.dart`

```dart
import 'package:flutter/material.dart';
import '../core/services/audio_handler.dart';

void main() {
  runApp(const NoirPlayerApp());
}

class NoirPlayerApp extends StatelessWidget {
  const NoirPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noir Player',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      routes: {
        '/library': (_) => const LibraryScreen(),
        '/player': (_) => const PlayerScreen(),
      },
    );
  }
}
```

*Bootstraps the app, initialises the audio service in `main()` and defines the navigation routes.*

### `library_screen.dart`

```dart
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  ...
}

class _LibraryScreenState extends State<LibraryScreen> {
  // TabController is used to switch between "All", "Artists", "Albums" tabs.
  // Each tab uses `on_audio_query` to fetch the relevant media.
}
```

*Shows a 4‑tabbed view of the local library and provides a navigation button to the “Now Playing” screen.*

### `audio_handler.dart`

```dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

Future<void> initAudioService() async {
  await AudioService.start(
    backgroundTaskEntrypoint: () => AudioServiceBackground.run(() => MyAudioTask()),
    androidNotificationChannelName: 'Noir Player',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidStopForegroundOnPause: false,
  );
}
```

*Wraps the complex background audio initialization logic.  
`MyAudioTask` extends `BackgroundAudioTask` (not shown in the snippet) and provides the `playerStateStream`, `mediaItem` and playback controls.*

### `player_screen.dart`

```dart
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  ...
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (_, snapshot) => ...
      ),
      bottomNavigationBar: StreamBuilder<PlaybackState>(
        stream: audioHandler.playbackState,
        builder: (_, snapshot) => ...
      ),
    );
  }
}
```

*Observes the global audio service streams and shows the currently playing track, its artwork, and the playback controls.*

---

## 📦 Dependencies

| Package | Purpose | Version |
|---------|---------|---------|
| `flutter` | SDK | ≥ 2.18 |
| `just_audio` | Lightweight audio playback | ^0.9.27 |
| `audio_service` | Background audio + notification handling | ^0.18.7 |
| `on_audio_query` | Read device’s music library & artwork | ^2.5.0 |
| `permission_handler` | Request storage permission on Android | ^10.2.0 |

> All packages are declared in `pubspec.yaml`.  
> Run `flutter pub get` to install them.

---

## 🤝 Contributing

Pull requests are welcome!  
Please open an issue first to discuss any major changes or new features.

---

## 📄 License

MIT © 2024 Noir Player.  
See [LICENSE](LICENSE) for details.

--- 

> **Enjoy building your own music player with Noir Player!**