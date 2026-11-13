# Ronron

A cat that lives at the bottom of your Mac's screen. It sleeps while you are away, wakes up when you type, and comes to sit on your window when it is time for a break.

## How it behaves

- **Asleep** by default, in its corner. Drag it wherever you like.
- **Awake** when you start typing. Type fast and it gets excited.
- **Back to sleep** a few seconds after you stop.
- **Break time**: after 45 minutes of work (25, 60 or 90 if you prefer), it walks to the window you are using, sits on it and asks for a break. It follows you if you switch windows.
- **Pet it** (one click) to send it home, or step away from the keyboard for two minutes: it counts that as your break.

## Install

Download [`Ronron.dmg`](https://github.com/AdrienBalcioglu/ronron/releases/latest/download/Ronron.dmg), open it and drag Ronron to Applications.

The app is not notarized by Apple. On the first launch after a download, right-click the app, choose Open, then confirm.

Ronron has no Dock icon. Its menu is the cat in the menu bar.

## Privacy

Ronron asks for no permission and never sees what you type.

- It reads a system counter of how many keys have been pressed, to know how fast you type. It does not know which keys.
- It reads how long the keyboard and mouse have been idle.
- It reads the position of the frontmost window, to sit on it. It does not read window titles or contents.

Nothing is recorded and nothing leaves your Mac.

## Build

```bash
./build.sh
```

It needs the Xcode Command Line Tools only, not Xcode. The result is a universal app (Apple silicon and Intel) for macOS 13 or later. The cat is drawn in code: `build/arm64 --render sheet.png` renders every pose.

## License

[MIT](LICENSE) © 2026 Adrien Balcioglu
