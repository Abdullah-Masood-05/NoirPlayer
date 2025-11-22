# Noir Player

> **Noir Player** is a lightweight Flutter music player that demonstrates:
> - Initialising the Android audio service with background playback support  
> - Querying the device’s media library using **`on_audio_query`**  
> - Playing, pausing, stopping, and showing the current media item in a dedicated “Now Playing” screen  
> - Keeping the UI responsive with `StreamBuilder`s  
> - Integrating Firebase authentication and core services

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
5. **Integrates Firebase for authentication and core services.**

---

## ✨ Features

| Feature                | File                                   | How it works                                  |
|------------------------|----------------------------------------|-----------------------------------------------|
| **Home Screen**        | [`screens/home/home_screen.dart`](lib/screens/home/home_screen.dart) | Drawer → Library tabs                         |
| **Tab‑based Library**  | [`screens/library/library_screen.dart`](lib/screens/library/library_screen.dart) | Uses `QueryArtworkWidget` & `OnAudioQuery`    |
| **Audio Service**      | [`core/services/audio_handler.dart`](lib/core/services/audio_handler.dart) | Wraps `audio_service` & `just_audio`          |
| **Now Playing UI**     | [`screens/player/player_screen.dart`](lib/screens/player/player_screen.dart) | Consumes `audioHandler.mediaItem` & `audioHandler.playbackState` |
| **Background playback**| `audio_service` + `just_audio`         | Keeps music playing in background             |
| **Theme switching**    | [`core/theme/app_theme.dart`](lib/core/theme/app_theme.dart) | Dark/light theme via `ValueNotifier`          |
| **Firebase integration**| [`firebase_options.dart`](lib/firebase_options.dart) | Core and Auth setup                           |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── services/
│   │   └── audio_handler.dart
│   └── theme/
│       └── app_theme.dart
├── screens/
│   ├── home/
│   │   └── home_screen.dart
│   ├── library/
│   │   ├── tabs/
│   │   │   ├── albums_tab.dart
│   │   │   ├── artists_tab.dart
│   │   │   ├── playlists_tab.dart
│   │   │   └── songs_tab.dart
│   │   └── library_screen.dart
│   ├── player/
│   │   └── player_screen.dart
│   ├── playlists/
│   │   ├── playlists_screen.dart
│   │   └── playlist_songs_screen.dart
│   ├── albums/
│   │   └── album_songs_screen.dart
│   ├── artist/
│   │   └── artist_songs_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   └── query_artwork_widget.dart
└── ...
```

---

## 🚀 Getting Started

### Prerequisites

| Platform | Requirement                       |
|----------|-----------------------------------|
| Android  | Flutter SDK ≥ 3.9, Android 6.0+   |

- Make sure you have a recent version of **Flutter** installed:
  ```bash
  flutter --version
  ```
- For Android you’ll need the **READ_EXTERNAL_STORAGE** permission in `AndroidManifest.xml`.  
  Noir Player requests permission via `on_audio_query`.

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
```

---

## 🧭 Workflow

### High‑level Flow Diagram

```
┌──────────────────┐
│   Noir Player UI │
│ (main.dart)      │
└────────┬─────────┘
         │ init
         ▼
┌──────────────────────┐
│ AudioServiceManager  │
│ (audio_handler.dart) │
└────────┬────────────┘
         │ start
         ▼
┌─────────────────────┐
│   Query Audio Files │
│ (on_audio_query)    │
└───────┬─────────────┘
        │ fetch list
        ▼
┌──────────────────────┐
│   LibraryScreen      │
│ (library_screen.dart)│
└───────┬──────────────┘
        │ tab navigation
        ▼
┌───────────────────────┐
│  PlayerScreen         │
│ (player_screen.dart)  │
└───────────────────────┘
```

> Each arrow represents a *stream* or *event* (e.g., `audioHandler.mediaItem`, `audioHandler.playbackState`).  
> The UI listens to these streams and updates automatically.

### Step‑by‑Step Walk‑through

| # | User Action                | App Reaction                                                                 | Code Path |
|---|----------------------------|------------------------------------------------------------------------------|-----------|
| 1 | Launch app                 | `main.dart` → `initAudioService()` → `HomeScreen`                            | [`main.dart`](lib/main.dart) |
| 2 | Open drawer → tap “Library”| `LibraryScreen` is pushed onto the Navigator stack                           | [`screens/home/home_screen.dart`](lib/screens/home/home_screen.dart) |
| 3 | `LibraryScreen` appears    | Tabs load (All / Artists / Albums). Each tab fetches tracks via `on_audio_query` and shows a list | [`screens/library/library_screen.dart`](lib/screens/library/library_screen.dart) |
| 4 | Tap a song                 | `audioHandler.play(Song)` is called, which: <br>• Updates `MediaItem` stream <br>• Calls `JustAudio.setFilePath()` <br>• Starts playback | [`core/services/audio_handler.dart`](lib/core/services/audio_handler.dart) |
| 5 | UI updates                 | `StreamBuilder<MediaItem?>` on `PlayerScreen` shows title/artist/album art    | [`screens/player/player_screen.dart`](lib/screens/player/player_screen.dart) |
| 6 | Play/Pause button          | `audioHandler.play()` / `audioHandler.pause()` toggles playback state         | [`screens/player/player_screen.dart`](lib/screens/player/player_screen.dart) |
| 7 | Stop/Back button           | `audioHandler.stop()` & `Navigator.pop()`                                    | [`screens/player/player_screen.dart`](lib/screens/player/player_screen.dart) |
| 8 | Close app                  | Background audio continues due to `audio_service` configuration              | [`core/services/audio_handler.dart`](lib/core/services/audio_handler.dart) |

---

## 🛠️ Architecture Details

### [`main.dart`](lib/main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();
  timeDilation = 1.0;
  runApp(NoirPlayerApp());
}

class NoirPlayerApp extends StatelessWidget {
  NoirPlayerApp({super.key});

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Noir Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/',
          routes: {
            '/': (context) => HomeScreen(themeNotifier: themeNotifier),
            '/player': (context) => const PlayerScreen(),
          },
        );
      },
    );
  }
}
```

*Bootstraps the app, initialises the audio service in `main()`, sets up theme switching, and defines navigation routes. Integrates Firebase core and authentication.*

### [`audio_handler.dart`](lib/core/services/audio_handler.dart)

```dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

Future<void> initAudioService() async {
  // Initialises background audio service
}
```

*Wraps the background audio initialisation logic. Provides streams for media item and playback state.*

### [`player_screen.dart`](lib/screens/player/player_screen.dart)

```dart
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  // Uses StreamBuilder to show current track and playback controls
}
```

*Observes the global audio service streams and shows the currently playing track, its artwork, and playback controls.*

---

## 📦 Dependencies

| Package             | Purpose                                 | Version   |
|---------------------|-----------------------------------------|-----------|
| `flutter`           | SDK                                     | ≥ 3.9.0   |
| `just_audio`        | Lightweight audio playback              | ^0.10.4   |
| `audio_service`     | Background audio + notification handling| ^0.18.18  |
| `on_audio_query`    | Read device’s music library & artwork   | ^2.9.0    |
| `permission_handler`| Request storage permission on Android   | ^12.0.1   |
| `provider`          | State management                        | ^6.1.2    |
| `shared_preferences`| Local storage                           | ^2.5.3    |
| `audio_session`     | Audio session management                | ^0.2.2    |
| `rxdart`            | Reactive streams                        | ^0.27.7   |
| `firebase_core`     | Firebase core                           | ^2.8.0    |
| `firebase_auth`     | Firebase authentication                 | ^4.6.0    |

> All packages are declared in [`pubspec.yaml`](pubspec.yaml).  
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