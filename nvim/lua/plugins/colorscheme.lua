return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      background = { dark = "mocha" },
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      -- TokyoNight's light variant. Its subdued brightness is easier on the eyes
      -- than pure white during long sessions.
      light_style = "day",
      day_brightness = 0.28,
      on_highlights = function(highlights, colors)
        -- Keep the active line subtle but visible.
        highlights.CursorLine = { bg = colors.bg_highlight }
        highlights.CursorColumn = { bg = colors.bg_highlight }
        highlights.CursorLineNr = { fg = colors.blue, bg = colors.bg_highlight, bold = true }
      end,
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = { contrast = "hard" },
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {},
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = require("config.theme").current(),
    },
  },
}
