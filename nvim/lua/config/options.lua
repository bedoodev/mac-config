-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.opt.list = false
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.showtabline = 2

-- Selections started with Shift use Select mode, as in conventional editors.
-- Typed characters replace the selection; Backspace deletes it.
vim.opt.keymodel = { "startsel", "stopsel" }
vim.opt.selectmode = { "key" }
vim.opt.selection = "inclusive"

-- A visible blinking Insert-mode cursor that uses the theme's Cursor colors.
-- The `a:` section applies blinking to all modes; Ghostty supports this.
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver35-Cursor/lCursor,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff500-blinkon500-Cursor/lCursor"
