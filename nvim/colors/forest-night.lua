vim.cmd("highlight clear")

if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "forest-night"

local colors = {
  bg = "#1a2125",
  fg = "#c9d1d9",

  selection = "#3a4a55",
  muted = "#4a5568",

  red = "#E91E63",
  yellow = "#F39C12",
  orange = "#E67E22",
  green = "#8FBC8F",
  cyan = "#4ECDC4",
  blue = "#4ECDC4",
  purple = "#9B59B6",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor
hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("NormalFloat", { fg = colors.fg, bg = colors.bg })

hi("CursorLine", { bg = "#202a2f" })
hi("Visual", { bg = colors.selection })
hi("Cursor", { fg = colors.bg, bg = "#e6f4eb" })
hi("lCursor", { fg = colors.bg, bg = "#e6f4eb" })
hi("CursorIM", { fg = colors.bg, bg = "#e6f4eb" })
hi("TermCursor", { fg = colors.bg, bg = "#e6f4eb" })
hi("TermCursorNC", { fg = colors.bg, bg = "#8fbc8f" })

hi("LineNr", { fg = colors.muted })
hi("CursorLineNr", { fg = colors.green, bold = true })

hi("Comment", { fg = colors.muted, italic = true })

-- Syntax
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

-- Diagnostics
hi("DiagnosticError", { fg = colors.red })
hi("DiagnosticWarn", { fg = colors.yellow })
hi("DiagnosticInfo", { fg = colors.cyan })
hi("DiagnosticHint", { fg = colors.green })

-- File explorer icons
hi("MiniIconsYellow", { fg = colors.yellow })
hi("MiniIconsCyan", { fg = colors.cyan })
hi("MiniIconsOrange", { fg = colors.orange })
