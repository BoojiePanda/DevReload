# DevReload

DevReload is a lightweight World of Warcraft addon for addon developers who reload the interface frequently. It provides a movable, resizable **Reload UI** button that can stay hidden when it is not needed.

## Features

- One-click interface reload
- Drag the button anywhere on screen
- Resize the button with the mouse wheel
- Close the button when development work is finished
- Matching black-and-pink Boojie styling
- Optional minimap button with LibDataBroker and LibDBIcon support
- Restore the button with a slash command or from the AddOns settings panel
- Saves position and size account-wide
- Remembers button visibility separately for each character

## Usage

The reload button is hidden by default for each character. Show it with either slash command:

```text
/dr
/devreload
```

- **Click** the button to reload the interface.
- **Drag** with the left mouse button to reposition it.
- **Scroll** over the button to resize it.
- Click the pink **X** to hide it.

You can also open **Settings > AddOns > DevReload** to show the reload button, reset its position and size, or show and hide its minimap button.

## Installation

1. Download or clone this repository.
2. Place the `DevReload` folder in your World of Warcraft Retail addon directory:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

3. Confirm the final path is:

   ```text
   Interface/AddOns/DevReload/DevReload.toc
   ```

4. Restart World of Warcraft or reload the interface.
5. Enable **DevReload** from the AddOns menu on the character-selection screen.

## Saved Data

DevReload uses `DevReloadDB` for the account-wide button position and size, and `DevReloadCharDB` for each character's visibility preference. All data remains local to your World of Warcraft installation.

## Compatibility

- World of Warcraft Retail
- Interface version: `120100`
- No dependencies

## Feedback and Issues

If you find a bug or have an idea for an improvement, open an issue on this repository with a clear description and reproduction steps.

## Author

Created by **BoojiePanda (SilverRavyn)**.
