# Kill Command Alert

A small addon for World of Warcraft 1.12 clients (Turtle WoW / OctoWoW) that shows the Kill Command icon in the middle of the screen, with a pulsing border and a sound, when Kill Command procs (spell ID 41827). The icon disappears when the proc is gone.

## Installation

1. Unzip the archive into `World of Warcraft\Interface\AddOns\`.
2. Make sure the result is `Interface\AddOns\KillCommandAlert\KillCommandAlert.toc`, not a nested folder.
3. Start the game and make sure the addon is enabled on the character selection screen.

## How the proc is detected

The addon has two detection methods. Both are on by default (`both` mode):

- **buff**: looks for a buff on you with spell ID 41827 (requires SuperWoW, which exposes spell IDs). Without SuperWoW it looks for a buff named "Kill Command" instead.
- **bar**: if Kill Command is on one of your action bars, the icon shows when the ability becomes usable and is not on cooldown (the global cooldown is ignored).

If the icon is shown all the time whenever Kill Command is off cooldown, switch to `/kca mode buff`.

## Slash commands

All commands start with `/kca`. Typing `/kca` on its own lists the commands and your current settings in the chat window.

### Display

| Command | What it does |
|---|---|
| `/kca test` | Shows the icon for 4 seconds and plays the selected sound, so you can see how it looks. |
| `/kca unlock` | Unlocks the icon and keeps it visible so you can drag it with the left mouse button. |
| `/kca lock` | Locks the icon in place and hides it again. The position is saved. |
| `/kca size <n>` | Sets the icon size in pixels, from 16 to 300. Example: `/kca size 90`. Default is 72. |

### Sound

| Command | What it does |
|---|---|
| `/kca sound` | Toggles the sound on or off. |
| `/kca sound on` | Turns the sound on. |
| `/kca sound off` | Turns the sound off. |
| `/kca sounds` | Lists the built-in sounds with numbers. The current sound is marked "<- selected". |
| `/kca play <number>` | Plays a built-in sound without changing your setting. Example: `/kca play 4`. |
| `/kca play <path>` | Plays any sound file or sound name. Example: `/kca play Sound\Spells\ShaysBell.wav`. |
| `/kca play` | Plays the currently selected sound. |
| `/kca sound <number>` | Selects a built-in sound, turns the sound on and plays it once. Example: `/kca sound 4`. |
| `/kca sound <path>` | Selects any sound file or sound name, turns the sound on and plays it once. |

Paths that contain `\` or end in `.wav` / `.mp3` are played as files. Anything else is played as a built-in sound name (for example `igQuestListComplete`). If a sound is silent, it doesn't exist in your client, so pick another one.

**Custom sound:** put a `.wav` or `.mp3` file in the addon folder, for example `alert.wav`, then run
`/kca sound Interface\AddOns\KillCommandAlert\alert.wav`.
Restart the game completely after adding the file; `/reload` is not enough for the 1.12 client to find new files.

### Detection and troubleshooting

| Command | What it does |
|---|---|
| `/kca mode both` | Uses both buff and action bar detection (default). |
| `/kca mode buff` | Only reacts to the Kill Command buff. |
| `/kca mode bar` | Only reacts to Kill Command becoming usable on your action bar. |
| `/kca debug` | Prints the action bar slot where Kill Command was found, and lists all your current buffs (with spell IDs if SuperWoW is installed). Run it while the proc is active if the icon doesn't show up. |
| `/kca reset` | Resets all settings (size, position, sound, mode) to the defaults. |

## Built-in sounds

| # | Sound |
|---|---|
| 1 | `Sound\Interface\RaidWarning.wav` (default) |
| 2 | `Sound\Interface\MapPing.wav` |
| 3 | `Sound\Interface\LevelUp.wav` |
| 4 | `Sound\Spells\ShaysBell.wav` |
| 5 | `Sound\Spells\PVPFlagTaken.wav` |
| 6 | `Sound\Doodad\BellTollAlliance.wav` |
| 7 | `Sound\Doodad\BellTollHorde.wav` |
| 8 | `Sound\Interface\iTellMessage.wav` |
| 9 | `igQuestListComplete` |
| 10 | `igPlayerInvite` |
| 11 | `igQuestFailed` |
| 12 | `TellMessage` |
| 13 | `AuctionWindowOpen` |
| 14 | `LEVELUPSOUND` |

## Saved settings

Settings are saved per account in `WTF\Account\<account>\SavedVariables\KillCommandAlert.lua`.
