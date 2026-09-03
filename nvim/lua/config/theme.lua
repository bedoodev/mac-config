local M = {}
local Modal = require("config.modal")

local fallback_theme = "catppuccin-mocha"
local state_file = vim.fn.stdpath("state") .. "/last-theme"
local themes = {
  { name = "catppuccin-mocha", label = "Catppuccin Mocha", background = "dark" },
  { name = "catppuccin-macchiato", label = "Catppuccin Macchiato", background = "dark" },
  { name = "catppuccin-frappe", label = "Catppuccin Frappe", background = "dark" },
  { name = "catppuccin-latte", label = "Catppuccin Latte", background = "light" },
  { name = "tokyonight-night", label = "TokyoNight Night", background = "dark" },
  { name = "tokyonight-storm", label = "TokyoNight Storm", background = "dark" },
  { name = "tokyonight-moon", label = "TokyoNight Moon", background = "dark" },
  { name = "tokyonight-day", label = "TokyoNight Day", background = "light" },
  { name = "gruvbox", label = "Gruvbox Dark", background = "dark" },
  { name = "kanagawa-wave", label = "Kanagawa Wave", background = "dark" },
  { name = "kanagawa-dragon", label = "Kanagawa Dragon", background = "dark" },
  { name = "kanagawa-lotus", label = "Kanagawa Lotus", background = "light" },
  { name = "rose-pine", label = "Rose Pine", background = "dark" },
  { name = "rose-pine-moon", label = "Rose Pine Moon", background = "dark" },
  { name = "rose-pine-dawn", label = "Rose Pine Dawn", background = "light" },
}
local theme_names = {}
for _, theme in ipairs(themes) do
  theme_names[theme.name] = theme
end

function M.current()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  local theme = ok and lines[1] or nil
  return theme_names[theme] and theme or fallback_theme
end

local function save(theme)
  vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
  local ok, err = pcall(vim.fn.writefile, { theme }, state_file)
  if not ok then
    vim.notify("Could not save theme preference: " .. err, vim.log.levels.WARN)
  end
end

local function set_theme(theme)
  vim.o.background = theme_names[theme].background
  vim.cmd.colorscheme(theme)
  save(theme)
end

local function close_theme_select()
  if not Snacks then
    return
  end
  for _, picker in ipairs(Snacks.picker.get({ source = "select" })) do
    picker:close()
  end
end

Modal.register("theme_select", close_theme_select)

vim.api.nvim_create_user_command("ThemeSelect", function()
  Modal.activate("theme_select")
  close_theme_select()
  Snacks.picker.select(themes, {
    prompt = "Select Theme",
    format_item = function(theme)
      return string.format("%-24s %s", theme.label, theme.background == "light" and "Light" or "Dark")
    end,
    snacks = { layout = { preset = "select" }, focus = "list" },
  }, function(theme)
    if theme then
      set_theme(theme.name)
    end
  end)
end, { desc = "Select and remember a colorscheme" })

vim.api.nvim_create_user_command("ThemeDark", function()
  set_theme("catppuccin-mocha")
end, { desc = "Use and remember Catppuccin Mocha" })

vim.api.nvim_create_user_command("ThemeLight", function()
  set_theme("tokyonight-day")
end, { desc = "Use and remember the light TokyoNight theme" })

return M
