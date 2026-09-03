return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Git diff" },
    },
    opts = {
      view = {
        -- Show the old (left) and new (right) versions side by side.
        default = { layout = "diff2_horizontal" },
      },
    },
  },
}
