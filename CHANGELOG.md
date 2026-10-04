# Changelog

Release notes for Noir Player. Each `## [x.y.z] - Title` section becomes the
notes of the matching GitHub release.

## [1.2.1] - Skip buttons and your own seek interval

### ⏯️ Player
- **Skip back and forward from the player screen.** New buttons beside previous / play / next jump back or ahead by your seek interval, and their icons show how far. Shuffle and repeat move to a row just below so everything fits comfortably, even on smaller phones.
- **Choose your seek interval.** Settings now has a **Playback** section where you pick 5, 10, 15, 30 or 60 seconds, or **Custom…** for anything from 1 to 300 seconds. The same interval is used by the player buttons, the notification and lock screen, and headset seek.

### 🔔 Notification & system media controls
- **The seek-buttons switch takes effect right away** and uses your interval, with no need to pause or skip a song first. On Android 13 and newer these buttons appear in the expanded media player, and some phones hide them.
- **Noir Player asks for notification permission once.** System surfaces such as OnePlus Live Alerts, the Samsung Now Bar and Xiaomi's island need it to show what's playing. If you say no, a short message points you to the app's settings. Whether a pop-up pill appears is up to your phone's system: OxygenOS 16, for example, shows music players as a Live Alert.
- **Clearer "Stop on application swipe" wording**, so it's plain what happens when you swipe Noir Player away from recents.

### ℹ️ About
- **About shows the app's real version**, read from the installed build (for example "Version 1.2.1 (7)").

### 📦 Installing
- **1.2.1 updates over 1.2.0 in place.** Your playlists and settings stay as they are.
- Noir Player for Android needs **Android 7.0 or newer**.

## [1.2.0] - Discover through Noir Player's server

### 🧭 Discover
- **Discover runs through Noir Player's server**, the same one Noir Player for Desktop uses. Trending tracks, search and downloads work right after you install, with nothing to set up.
- **Bring your own keys if you like.** Under **Settings → Discover** you can add your own **Last.fm**, **YouTube Data API** or **RapidAPI** key. Any service you add a key for is called directly with it; the rest keep going through Noir Player's server. Keys stay on your device, and clearing a field hands that service back to the server.

### 🎵 Now playing, everywhere
- **Cleaner song info on your system media controls.** The notification, the lock screen, the Samsung Now Bar and other system media controls show the song's title, artist and album without "<unknown>" placeholders: a song with no artist tag reads "Unknown Artist", and a missing album is simply left out.
- **Cover art from the first moment.** The song Noir Player restores when it starts shows its cover art right away, even before you press play.

### 📱 iPhone
- **An unsigned iOS build is attached** to this release as `NoirPlayer-iOS-v1.2.0-unsigned.ipa`. Sideload it with a tool such as Sideloadly or AltStore.

### ⚠️ Before you install
- **1.2.0 is signed with a new, permanent release key.** If an earlier version of Noir Player is installed, Android won't update over it, so **uninstall it first**, then install 1.2.0. Playlists and settings stored on the device aren't carried over.
- From here on, updates install over 1.2.0 normally.
- Noir Player for Android needs **Android 7.0 or newer**.
