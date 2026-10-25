# AddonListPlus

A searchable in-game AddOn list for **World of Warcraft 3.3.5a (Wrath of the Lich King)**, modelled on the AddOn list from the modern client.

## Features

- **Search bar**: matches addon names. Several words narrow the results (`bag tool` finds Bagnon Tooltips).
- **Presets**: save which addons are on as a named preset and switch between them from the dropdown, like loadouts in the modern talent window. See [Presets](#presets).
- **Sub-addons nested under their parent**: DBM modules under DBM Core, ElvUI plugins under ElvUI, AtlasLoot modules under AtlasLoot, and so on. Groups can be collapsed.
- **Okay turns into Reload UI** as soon as a change needs a reload. Cancel, the X button and Escape undo changes made since you opened the window.
- **Memory usage**: the total, how many addons are loaded and the largest one, plus per-addon memory on each row.
- **Load out of date AddOns** checkbox, like the login screen.
- **Smart toggling**: clicking a parent toggles its sub-addons too (shift-click changes only the parent). Turning an addon on also turns on the addons it needs.
- **Icons** for many popular addons.
- **ElvUI support**: uses ElvUI's skin when ElvUI is loaded, and the Blizzard style otherwise.

## Opening it

- **Esc menu → AddOns**
- `/addons` or `/alp`

If ElvUI Enhanced or Addon Control Panel already adds an AddOns button to the Esc menu, that button opens this list instead, so you never get two buttons. Without them, AddonListPlus adds its own button.

## Presets

Open the dropdown in the top-left corner:

- **New Preset** saves the addons that are currently ticked under a name you choose.
- **Click a preset** to tick its addons. Press **Reload UI** to apply it, or **Cancel** to undo.
- **Note icon** on a preset line: overwrite that preset with the current ticks.
- **Red X** on a preset line: delete that preset (asks first).

Presets are shared by all characters on your account. The dropdown shows the preset that matches your current ticks, or **Custom** if none does. Addons installed after a preset was saved are left as they are when you apply it.

## Installation

1. Download `AddonListPlus-vX.Y.Z.zip` from the [Releases](../../releases) page.
2. Extract it into `World of Warcraft\Interface\AddOns\`.
3. Make sure the folder is named exactly `AddonListPlus` (with `AddonListPlus.toc` directly inside it).

> If you use GitHub's green **Code → Download ZIP** button instead, rename the extracted folder from `AddonListPlus-main` to `AddonListPlus`. Otherwise the game won't load it.

## Limitations

- **In-game only.** On 3.3.5 the login/character screen can't be changed by addons; addons only load once you enter the world.
- **Current character only.** In-game, 3.3.5 can only enable or disable addons for the character you are logged in on. The "All characters" option exists only on the login screen.

## License

[MIT](LICENSE). You're free to use, modify and share it, as long as the license notice stays included.
