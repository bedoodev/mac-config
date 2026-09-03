return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    build = "cd app && npm install",
    ft = { "markdown" },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
    opts = {},
    keys = {
      {
        "<leader>mp",
        "<cmd>RenderMarkdown toggle<cr>",
        ft = "markdown",
        desc = "Toggle Markdown rendering",
      },
      {
        "<leader>mP",
        "<cmd>RenderMarkdown preview<cr>",
        ft = "markdown",
        desc = "Side Markdown preview",
      },
    },
  },
}
