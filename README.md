# clock.nvim

An analog watch face for Neovim, rendered as Unicode art in a floating window.

## Features

- **Analog clock face** with Arabic numerals, minute markers, and a circular bezel
- **Four hands** — hour (█ block), minute (thin line), second (• dot), and GMT (red)
- **Date window** showing day of week and date, centered above the dial
- **Configurable GMT hand** to track any timezone offset from UTC
- **Round floating window** that blends seamlessly with your editor background
- **Lualine component** for a compact time display in your statusline

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'airkewld/clock-nvim',
  opts = {
    gmt_offset = 0, -- UTC offset for the GMT hand (default: 0)
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'airkewld/clock-nvim',
  config = function()
    require('clock').setup()
  end,
}
```

### Manual

Clone the repository into your Neovim packages directory:

```sh
git clone https://github.com/airkewld/clock-nvim \
  ~/.local/share/nvim/site/pack/plugins/start/clock-nvim
```

## Configuration

```lua
require('clock').setup({
  -- UTC offset for the GMT (red) hand.
  -- Examples:
  --   0    → UTC (default)
  --   9    → JST (UTC+9)
  --  -5    → EST (UTC-5)
  --   5.5  → IST (UTC+5:30)
  gmt_offset = 0,
})
```

## Usage

| Command    | Keymap       | Description           |
|------------|--------------|-----------------------|
| `:Clock`   | `<leader>ck` | Toggle the clock face |

Press `q` or `<Esc>` to close the floating window.

## Reading the Hands

| Hand   | Style        | Color | Length  |
|--------|--------------|-------|---------|
| Hour   | █ solid block| white | short   |
| Minute | ─/│ thin line| white | medium  |
| Second | • dot trail  | gray  | long    |
| GMT    | ─/│ thin line| red   | medium  |

The GMT hand completes one full rotation every 24 hours (unlike the hour hand which rotates every 12 hours).

## Statusline

clock.nvim includes a [lualine](https://github.com/nvim-lualine/lualine.nvim) component:

```lua
require('lualine').setup({
  sections = {
    lualine_x = {
      require('clock.statusline').component,
    },
  },
})
```

This displays the local time alongside the tracked GMT time, e.g. `14:30 (14:30 UTC)` or `14:30 (23:30 UTC+9)`.

## Highlight Groups

All highlight groups can be overridden after calling `setup()`:

| Group              | Default                          | Description                    |
|--------------------|----------------------------------|--------------------------------|
| `ClockDial`        | `bg=#1a3a2a fg=#c8d8c8`          | Dial face background           |
| `ClockCase`        | `fg=#888888 bg=#1a3a2a`          | Bezel outline (● dots)         |
| `ClockNumeral`     | `fg=#ffffff bg=#1a3a2a bold`     | Hour numerals (1–12)           |
| `ClockTick`        | `fg=#c8d8c8 bg=#1a3a2a`         | Minute tick marks              |
| `ClockHourHand`    | `fg=#ffffff bg=#1a3a2a bold`     | Hour hand                      |
| `ClockMinuteHand`  | `fg=#ffffff bg=#1a3a2a bold`     | Minute hand                    |
| `ClockSecondHand`  | `fg=#dddddd bg=#1a3a2a`         | Second hand                    |
| `ClockGmtHand`     | `fg=#cc3333 bg=#1a3a2a bold`    | GMT hand                       |
| `ClockDate`        | `fg=#000000 bg=#ffffff bold`     | Date window                    |
| `ClockBrand`       | `fg=#668866 bg=#1a3a2a`         | Brand text                     |
| `ClockBg`          | links to `Normal`                | Area outside the dial          |
