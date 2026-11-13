# Ronron

A cat that lives at the bottom of your Mac's screen. It sleeps while you are away, wakes up when you type, and comes to sit on your window when it is time for a break.

Pair it with a friend's cat, and the two cats keep each other company while you both work.

## On your own

- **Asleep** by default, in its corner. Drag it wherever you like.
- **Awake** when you start typing. Type fast and it gets excited.
- **Back to sleep** a few seconds after you stop.
- **Break time**: after 45 minutes of work (25, 60 or 90 if you prefer), it walks to the window you are using, sits on it and asks for a break. It follows you if you switch windows.
- **Pet it** (one click) to send it home, or step away from the keyboard for two minutes: it counts that as your break.

Choose its coat in the menu, under **My Cat**: ginger, black, white, grey, calico or siamese. Give it a name there too.

## With a friend

1. One of you chooses **Friend → Invite a Friend…** and gets an eight-character code.
2. The other chooses **Friend → Enter a Friend's Code…** and types it.

From then on, whenever your friend is at their Mac, their cat walks onto your screen and settles next to yours. And yours does the same on theirs.

| You two | The cats |
| --- | --- |
| Both working | Sit side by side |
| Both typing flat out | Chase each other and a ball of yarn |
| One stops | That one's cat falls asleep, the other keeps watch |
| Both stop | Sleep curled up together |
| One leaves their Mac | Their cat walks off the screen |

Click your friend's cat to pet it: hearts appear on your friend's screen. It is a way to say hello without writing anything.

**Invisible** keeps your cat at home when you would rather not be seen.

## Privacy

Ronron asks for no permission and never sees what you type.

- It reads a system counter of how many keys have been pressed, to know how fast you type. It does not know which keys.
- It reads how long the keyboard and mouse have been idle.
- It reads the position of the frontmost window, to sit on it. It does not read window titles or contents.

Without a friend, nothing leaves your Mac.

With a friend, your cat sends one of four words (away, resting, working, typing flat out), its name and its coat. Nothing else. These messages are encrypted on your Mac with a key derived from your pairing code, then passed through a public relay, [ntfy.sh](https://ntfy.sh). The relay sees unreadable data on a channel whose name is also derived from the code. Keep the code between the two of you.

The relay is a free public service. It allows about 250 messages a day, so the cats report changes with a short delay (up to 45 seconds) rather than instantly. If the relay is down, each cat simply carries on alone.

## Install

Download [`Ronron.dmg`](https://github.com/AdrienBalcioglu/ronron/releases/latest/download/Ronron.dmg), open it and drag Ronron to Applications.

The app is not notarized by Apple. On the first launch after a download, right-click the app, choose Open, then confirm.

Ronron has no Dock icon. Its menu is the cat in the menu bar.

## Build

```bash
./build.sh
```

It needs the Xcode Command Line Tools only, not Xcode. The result is a universal app (Apple silicon and Intel) for macOS 13 or later.

The cats are drawn in code: `build/arm64 --render sheet.png` renders every coat and scene. To try the friend link on a single Mac, run two copies with `--profile a` and `--profile b`, and force their activity with `--simulate resting`, `working` or `intense`.

## License

[MIT](LICENSE) © 2026 Adrien Balcioglu
