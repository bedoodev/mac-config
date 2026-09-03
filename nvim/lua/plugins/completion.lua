return {
  {
    "saghen/blink.cmp",
    opts = {
      cmdline = {
        keymap = {
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
        },
      },
    },
  },
}
