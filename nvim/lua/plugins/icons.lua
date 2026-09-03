return {
  {
    "nvim-mini/mini.icons",
    opts = {
      extension = {
        py = { glyph = "", hl = "MiniIconsYellow" },
        go = { glyph = "", hl = "MiniIconsCyan" },
      },
      file = {
        [".gitignore"] = { glyph = "󰊢", hl = "MiniIconsOrange" },
        [".gitattributes"] = { glyph = "󰊢", hl = "MiniIconsOrange" },
        [".gitconfig"] = { glyph = "󰊢", hl = "MiniIconsOrange" },
        ["go.mod"] = { glyph = "", hl = "MiniIconsCyan" },
        ["go.sum"] = { glyph = "", hl = "MiniIconsCyan" },
        ["pyproject.toml"] = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
  },
}
