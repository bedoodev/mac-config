vim.cmd("highlight clear")

if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "light"
vim.g.colors_name = "forest-light"

local colors = {
  -- A slightly warm, low-contrast background instead of pure white.
  bg = "#edf1ee",
  fg = "#2c383d",
  selection = "#abc8bb",
  muted = "#64747c",
  red = "#c0395b",
  yellow = "#a76a00",
  orange = "#bf6518",
  green = "#3f7d5a",
  cyan = "#137b78",
  blue = "#1b6e9b",
  purple = "#8055a6",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("NormalFloat", { fg = colors.fg, bg = colors.bg })
-- Make the active line distinct without a harsh bright color.
hi("CursorLine", { bg = "#b9cec3" })
hi("CursorColumn", { bg = "#b9cec3" })
hi("Visual", { bg = colors.selection })
hi("Cursor", { fg = colors.bg, bg = "#073f32" })
hi("lCursor", { fg = colors.bg, bg = "#073f32" })
hi("CursorIM", { fg = colors.bg, bg = "#073f32" })
hi("TermCursor", { fg = colors.bg, bg = "#073f32" })
hi("TermCursorNC", { fg = colors.bg, bg = "#45675b" })
hi("LineNr", { fg = colors.muted })
hi("CursorLineNr", { fg = "#174f3d", bg = "#b9cec3", bold = true })
hi("Comment", { fg = colors.muted, italic = true })

hi("String", { fg = colors.green })
hi("Character", { fg = colors.green })
hi("Number", { fg = colors.orange })
hi("Boolean", { fg = colors.orange })
hi("Keyword", { fg = colors.purple })
hi("Conditional", { fg = colors.purple })
hi("Repeat", { fg = colors.purple })
hi("Function", { fg = colors.cyan })
hi("Identifier", { fg = colors.fg })
hi("Type", { fg = colors.yellow })
hi("Constant", { fg = colors.orange })
hi("Operator", { fg = colors.cyan })
hi("Delimiter", { fg = colors.fg })

hi("DiagnosticError", { fg = colors.red })
hi("DiagnosticWarn", { fg = colors.yellow })
hi("DiagnosticInfo", { fg = colors.cyan })
hi("DiagnosticHint", { fg = colors.green })

hi("MiniIconsYellow", { fg = colors.yellow })
hi("MiniIconsCyan", { fg = colors.cyan })
hi("MiniIconsOrange", { fg = colors.orange })
