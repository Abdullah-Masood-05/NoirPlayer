# Changelog

Release notes for Noir Player. Each `## [x.y.z] - Title` section becomes the
notes of the matching GitHub release.

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
