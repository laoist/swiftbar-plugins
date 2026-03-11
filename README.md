# swiftbar-plugins

Personal SwiftBar plugins for macOS.

## Dependencies

- [SwiftBar](https://github.com/swiftbar/SwiftBar) — `brew install swiftbar`
- [media-control](https://github.com/ungive/media-control) — `brew tap ungive/media-control && brew install media-control`

## Setup

Set SwiftBar's plugin folder to this repo, or clone it there directly:
```
git clone https://github.com/laoist/swiftbar-plugins ~/Library/Application\ Support/SwiftBar/Plugins
```

## Plugins

### media/nowplaying.5s.py

Displays the currently playing Tidal track in the menu bar. Shows album art,
artist, title, album, and a live progress bar in a popover on click.

Only shows output when Tidal is the active source. To add other sources (e.g.
Spotify, Apple Music), add their bundle identifiers to `ALLOWED_SOURCES` in the
script. To find a source's bundle identifier, play something and run:

```sh
media-control get | jq '.bundleIdentifier'
```

![Now Playing](/.github/screenshots/nowplaying.png)
