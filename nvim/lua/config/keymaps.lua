-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local map = vim.keymap.set

-- Browse Ex command history with the arrow keys.
map("c", "<Up>", "<C-p>", { desc = "Previous command" })
map("c", "<Down>", "<C-n>", { desc = "Next command" })

-- Buffer tabs: quick navigation and closing
map("n", "W", function()
  -- Diffview opened from Git Status is a separate view/tab page.
  -- Close it and return to the selection modal instead of deleting it like a buffer.
  local has_diffview, diffview = pcall(require, "diffview.lib")
  if has_diffview and diffview.get_current_view() then
    vim.cmd("DiffviewClose")
    vim.schedule(function()
      Snacks.picker.git_status({ cwd = LazyVim.root.git() })
    end)
    return
  end

  local current = vim.api.nvim_get_current_buf()

  -- Explorer, terminal, and temporary windows are not tabs; do not close them
  -- with Shift+W.
  if vim.bo[current].buftype ~= "" then
    return
  end

  -- Show Neovim's built-in safety warning for an unsaved file.
  if vim.bo[current].modified then
    vim.cmd("bdelete")
    return
  end

  local buffers = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buflisted and vim.bo[buffer].buftype == "" then
      table.insert(buffers, buffer)
    end
  end

  -- Switch to the next file in the same editor window so focus does not move
  -- to the explorer.
  local next_buffer
  for index, buffer in ipairs(buffers) do
    if buffer == current and #buffers > 1 then
      next_buffer = buffers[index % #buffers + 1]
      break
    end
  end

  if next_buffer then
    vim.api.nvim_win_set_buf(0, next_buffer)
  end
  vim.cmd("bdelete " .. current)

  -- If the closed file was the last tab, open the explorer instead of an empty buffer.
  if not next_buffer then
    vim.schedule(function()
      if not Snacks then
        return
      end
      local explorer = Snacks.picker.get({ source = "explorer" })[1]
      if explorer then
        explorer:focus()
      else
        Snacks.explorer({ cwd = LazyVim.root() })
      end
    end)
  end
end, { desc = "Close tab" })
map("n", "E", "<cmd>bnext<cr>", { desc = "Next tab" })
map("n", "Q", "<cmd>bprevious<cr>", { desc = "Previous tab" })
map("n", "p", "<Nop>", { desc = "Disable paste" })
map({ "n", "i" }, "<C-b>", "<cmd>ExplorerToggle<cr>", { desc = "Toggle explorer" })

-- Cmd + S: save
for _, lhs in ipairs({ "<D-s>", "<Esc>[115;9u" }) do
  map({ "n", "i", "x", "s" }, lhs, "<Cmd>write<CR>", { desc = "Save file" })
end

-- Cmd + Z: undo; Cmd + Shift + Z: redo
local function map_command_z(lhs)
  map("n", lhs, "u", { desc = "Undo" })
  map("i", lhs, "<C-o>u", { desc = "Undo" })
  map({ "x", "s" }, lhs, "<Esc>u", { desc = "Undo" })
end

local function map_command_shift_z(lhs)
  map("n", lhs, "<C-r>", { desc = "Redo" })
  map("i", lhs, "<C-o><C-r>", { desc = "Redo" })
  map({ "x", "s" }, lhs, "<Esc><C-r>", { desc = "Redo" })
end

for _, lhs in ipairs({ "<D-z>", "<C-z>", "<Esc>[122;9u", "<Esc>[122~" }) do
  map_command_z(lhs)
end

for _, lhs in ipairs({ "<D-S-z>", "<D-Z>", "<C-y>", "<Esc>[122;10u", "<Esc>[90;9u", "<Esc>[90~" }) do
  map_command_shift_z(lhs)
end

-- Cmd + A: select the complete current buffer in Select mode.
for _, lhs in ipairs({ "<D-a>", "<C-a>", "<Esc>[97;9u", "<Esc>[97~" }) do
  map("n", lhs, "ggVG<C-g>", { desc = "Select all" })
  map("i", lhs, "<Esc>ggVG<C-g>", { desc = "Select all" })
  map({ "x", "s" }, lhs, "<Esc>ggVG<C-g>", { desc = "Select all" })
end

-- Ghostty can send Command/Option + arrow keys as Neovim's native special keys.
-- These mappings catch them directly without requiring CSI sequences.
map({ "n", "v" }, "<D-Left>", "0")
map("i", "<D-Left>", "<C-o>0")
map({ "n", "v" }, "<D-Right>", "$")
map("i", "<D-Right>", "<C-o>$")
map({ "n", "v" }, "<D-Up>", "gg")
map("i", "<D-Up>", "<C-o>gg")
map({ "n", "v" }, "<D-Down>", "G")
map("i", "<D-Down>", "<C-o>G")

-- Ghostty converts Cmd+Arrow keys to standard Home/End sequences.
map({ "n", "x" }, "<Home>", "0", { desc = "Start of line" })
map("i", "<Home>", "<C-o>0", { desc = "Start of line" })
map({ "n", "x" }, "<End>", "$", { desc = "End of line" })
map("i", "<End>", "<C-o>$", { desc = "End of line" })
map({ "n", "x" }, "<C-Home>", "gg", { desc = "Start of file" })
map("i", "<C-Home>", "<C-o>gg", { desc = "Start of file" })
map({ "n", "x" }, "<C-End>", "G", { desc = "End of file" })
map("i", "<C-End>", "<C-o>G", { desc = "End of file" })
map({ "n", "v" }, "<M-Left>", "b")
map("i", "<M-Left>", "<C-o>b")
map({ "n", "v" }, "<M-Right>", "w")
map("i", "<M-Right>", "<C-o>w")
map("n", "<D-BS>", "dd", { desc = "Delete line" })
map("i", "<D-BS>", "<C-o>dd", { desc = "Delete line" })
map("n", "<M-BS>", "db", { desc = "Delete previous word" })
map("i", "<M-BS>", "<C-w>", { desc = "Delete previous word" })

-- Cmd + Left: start of line
map({ "n", "v" }, "<Esc>[99~", "0")
map("i", "<Esc>[99~", "<C-o>0")
map({ "n", "v" }, "<Esc>[9~", "0")
map("i", "<Esc>[9~", "<C-o>0")
map({ "n", "v" }, "<Esc>[1;9D", "0")
map("i", "<Esc>[1;9D", "<C-o>0")

-- Cmd + Right: end of line
map({ "n", "v" }, "<Esc>[100~", "$")
map("i", "<Esc>[100~", "<C-o>$")
map({ "n", "v" }, "<Esc>[00~", "$")
map("i", "<Esc>[00~", "<C-o>$")
map({ "n", "v" }, "<Esc>[1;9C", "$")
map("i", "<Esc>[1;9C", "<C-o>$")

-- Cmd + Up: start of file
map({ "n", "v" }, "<Esc>[101~", "gg")
map("i", "<Esc>[101~", "<C-o>gg")
map({ "n", "v" }, "<Esc>[1;9A", "gg")
map("i", "<Esc>[1;9A", "<C-o>gg")

-- Cmd + Down: end of file
map({ "n", "v" }, "<Esc>[102~", "G")
map("i", "<Esc>[102~", "<C-o>G")
map({ "n", "v" }, "<Esc>[1;9B", "G")
map("i", "<Esc>[1;9B", "<C-o>G")

-- Option + Left/Right: move by word
map({ "n", "v" }, "<Esc>[1;3D", "b")
map("i", "<Esc>[1;3D", "<C-o>b")
map({ "n", "v" }, "<Esc>[;3D", "b")
map("i", "<Esc>[;3D", "<C-o>b")
map({ "n", "v" }, "<Esc>b", "b")
map("i", "<Esc>b", "<C-o>b")
map({ "n", "v" }, "<Esc>[1;3C", "w")
map("i", "<Esc>[1;3C", "<C-o>w")
map({ "n", "v" }, "<Esc>[;3C", "w")
map("i", "<Esc>[;3C", "<C-o>w")
map({ "n", "v" }, "<Esc>f", "w")
map("i", "<Esc>f", "<C-o>w")

-- Cmd + Backspace: delete line; Option + Backspace: delete previous word
map("n", "<Esc>[127;9u", "dd", { desc = "Delete line" })
map("i", "<Esc>[127;9u", "<C-o>dd", { desc = "Delete line" })
map("n", "<Esc>[27;9u", "dd", { desc = "Delete line" })
map("i", "<Esc>[27;9u", "<C-o>dd", { desc = "Delete line" })
map("n", "<Esc>[127;3u", "db", { desc = "Delete previous word" })
map("i", "<Esc>[127;3u", "<C-w>", { desc = "Delete previous word" })
map("n", "<Esc>[27;3u", "db", { desc = "Delete previous word" })
map("i", "<Esc>[27;3u", "<C-w>", { desc = "Delete previous word" })
map("n", "<Esc><BS>", "db", { desc = "Delete previous word" })
map("i", "<Esc><BS>", "<C-w>", { desc = "Delete previous word" })

-- Editor-style selection ----------------------------------------------------
-- Ghostty sends custom Cmd+Shift sequences; in Select mode, typed characters
-- or Backspace replace the selection.
local function select_with(lhs, normal_rhs, insert_rhs, select_rhs, desc)
  map("n", lhs, normal_rhs, { desc = desc })
  map("i", lhs, insert_rhs, { desc = desc })
  map("s", lhs, select_rhs, { desc = desc })
  map("x", lhs, select_rhs:gsub("^<C%-o>", ""), { desc = desc })
end

-- Cmd + Shift + Arrow: select to a line/file boundary
select_with("<S-Home>", "gh<C-o>0", "<Esc>gh<C-o>0", "<C-o>0", "Select to start of line")
select_with("<S-End>", "gh<C-o>$", "<Esc>gh<C-o>$", "<C-o>$", "Select to end of line")
select_with("<C-S-Home>", "gh<C-o>gg", "<Esc>gh<C-o>gg", "<C-o>gg", "Select to start of file")
select_with("<C-S-End>", "gh<C-o>G", "<Esc>gh<C-o>G", "<C-o>G", "Select to end of file")

select_with("<Esc>[103~", "gh<C-o>0", "<Esc>gh<C-o>0", "<C-o>0", "Select to start of line")
select_with("<Esc>[104~", "gh<C-o>$", "<Esc>gh<C-o>$", "<C-o>$", "Select to end of line")
select_with("<Esc>[105~", "gh<C-o>gg", "<Esc>gh<C-o>gg", "<C-o>gg", "Select to start of file")
select_with("<Esc>[106~", "gh<C-o>G", "<Esc>gh<C-o>G", "<C-o>G", "Select to end of file")

-- Fallbacks for when the GUI/kitty protocol resolves these keys directly
select_with("<D-S-Left>", "gh<C-o>0", "<Esc>gh<C-o>0", "<C-o>0", "Select to start of line")
select_with("<D-S-Right>", "gh<C-o>$", "<Esc>gh<C-o>$", "<C-o>$", "Select to end of line")
select_with("<D-S-Up>", "gh<C-o>gg", "<Esc>gh<C-o>gg", "<C-o>gg", "Select to start of file")
select_with("<D-S-Down>", "gh<C-o>G", "<Esc>gh<C-o>G", "<C-o>G", "Select to end of file")

-- Shift + Option + Left/Right: select by word
select_with("<M-S-Left>", "gh<C-o>b", "<Esc>gh<C-o>b", "<C-o>b", "Select to previous word")
select_with("<M-S-Right>", "gh<C-o>e", "<Esc>gh<C-o>e", "<C-o>e", "Select to end of word")
select_with("<Esc>[1;4D", "gh<C-o>b", "<Esc>gh<C-o>b", "<C-o>b", "Select to previous word")
select_with("<Esc>[1;4C", "gh<C-o>e", "<Esc>gh<C-o>e", "<C-o>e", "Select to end of word")

-- Copy or cut Select/Visual mode selections to the system clipboard.
for _, lhs in ipairs({ "<D-c>", "<Esc>[99;9u" }) do
  map("n", lhs, '"+yy', { desc = "Copy line" })
  map("i", lhs, '<C-o>"+yy', { desc = "Copy line" })
  map("s", lhs, '<C-o>"+y', { desc = "Copy selection" })
  map("x", lhs, '"+y', { desc = "Copy selection" })
end

for _, lhs in ipairs({ "<D-x>", "<Esc>[120;9u" }) do
  map("s", lhs, '<C-o>"+x', { desc = "Cut selection" })
  map("x", lhs, '"+x', { desc = "Cut selection" })
end
