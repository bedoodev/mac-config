local Modal = require("config.modal")
local diff_stats_cache = {}
local explorer_width

local function add_diff_stats(stats, root, path, additions, deletions)
  path = vim.fs.normalize(path)
  while path and path:sub(1, #root) == root do
    local current = stats[path] or { additions = 0, deletions = 0 }
    current.additions = current.additions + additions
    current.deletions = current.deletions + deletions
    stats[path] = current
    if path == root then
      break
    end
    path = vim.fs.dirname(path)
  end
end

local function load_diff_stats(root)
  local stats = {}
  local diff = vim.system({ "git", "--no-pager", "diff", "--no-renames", "--numstat", "HEAD", "--" }, {
    cwd = root,
    text = true,
  }):wait()

  -- A repository without its first commit has no HEAD yet.
  if diff.code ~= 0 then
    diff = vim.system({ "git", "--no-pager", "diff", "--cached", "--no-renames", "--numstat", "--" }, {
      cwd = root,
      text = true,
    }):wait()
  end

  for line in (diff.stdout or ""):gmatch("[^\r\n]+") do
    local additions, deletions, path = line:match("^(%S+)\t(%S+)\t(.+)$")
    if additions and additions ~= "-" and deletions ~= "-" then
      add_diff_stats(stats, root, root .. "/" .. path, tonumber(additions), tonumber(deletions))
    end
  end

  local untracked = vim.system({ "git", "ls-files", "--others", "--exclude-standard", "-z" }, {
    cwd = root,
    text = true,
  }):wait()
  for _, path in ipairs(vim.split(untracked.stdout or "", "\0", { plain = true, trimempty = true })) do
    local file = root .. "/" .. path
    local ok, lines = pcall(vim.fn.readfile, file)
    add_diff_stats(stats, root, file, ok and #lines or 0, 0)
  end

  return stats
end

local function explorer_diff_stats(root)
  root = vim.fs.normalize(root)
  local now = vim.uv.hrtime() / 1e6
  local cached = diff_stats_cache[root]
  if not cached or now - cached.updated > 1000 then
    cached = { updated = now, stats = load_diff_stats(root) }
    diff_stats_cache[root] = cached
  end
  return cached.stats
end

local function format_explorer_item(item, picker)
  local status = item.status
  item.status = nil
  local ok, formatted = pcall(Snacks.picker.format.file, item, picker)
  item.status = status
  if not ok then
    error(formatted)
  end

  if not status then
    return formatted
  end

  local root = Snacks.git.get_root(picker:cwd())
  local stat = root and explorer_diff_stats(root)[vim.fs.normalize(item.file)] or nil
  if not stat then
    return formatted
  end

  local text = {}
  if stat.additions > 0 or stat.deletions == 0 then
    text[#text + 1] = { "+" .. stat.additions, "SnacksPickerGitStatusAdded" }
  end
  if stat.deletions > 0 then
    if #text > 0 then
      text[#text + 1] = { " " }
    end
    text[#text + 1] = { "-" .. stat.deletions, "SnacksPickerGitStatusDeleted" }
  end
  formatted[#formatted + 1] = {
    col = 0,
    virt_text = text,
    virt_text_pos = "right_align",
    hl_mode = "combine",
  }
  return formatted
end

local function open_selected_diff(picker)
  local item = picker:selected({ fallback = true })[1]
  if not item then
    return
  end

  picker:close()
  vim.cmd("DiffviewOpen HEAD -- " .. vim.fn.fnameescape(item.file))
  vim.schedule(function()
    vim.cmd("DiffviewToggleFiles")
  end)
end

local function open_git_status()
  local cwd = vim.b.git_ui_root or LazyVim.root.git()
  Modal.activate("git_status")
  Snacks.picker.git_status({ cwd = cwd })
end

vim.api.nvim_create_user_command("GitStatus", open_git_status, { desc = "List Git changes" })

-- User commands must start with an uppercase letter, so expand `:gs` to
-- `:GitStatus` on the command line.
vim.cmd([[cnoreabbrev <expr> gs getcmdtype() ==# ':' && getcmdline() ==# 'gs' ? 'GitStatus' : 'gs']])

local function open_git_branches()
  local cwd = vim.b.git_ui_root or LazyVim.root.git()
  Modal.activate("git_branches")
  -- List local and remote branches together. Enter safely runs `git checkout`
  -- for the selected branch.
  Snacks.picker.git_branches({ all = true, cwd = cwd })
end

vim.api.nvim_create_user_command("GitBranches", open_git_branches, { desc = "List Git branches" })
vim.cmd([[cnoreabbrev <expr> gb getcmdtype() ==# ':' && getcmdline() ==# 'gb' ? 'GitBranches' : 'gb']])

local function discard_all_git_changes()
  -- Snacks window keymaps pass a window object instead of the picker.
  -- Finding the active Git Status picker directly is safe.
  local picker = Snacks.picker.get({ source = "git_status" })[1]
  if not picker then
    Snacks.notify.warn("No open Git Status window found", { title = "Git Status" })
    return
  end

  local cwd = picker:cwd() or vim.fn.getcwd()
  Snacks.picker.util.confirm(
    "Discard all staged, unstaged, and untracked file changes? This cannot be undone.",
    function()
      Snacks.picker.util.cmd(
        { "git", "restore", "--source=HEAD", "--staged", "--worktree", "." },
        function(_, restore_code)
          if restore_code ~= 0 then
            Snacks.notify.error("Could not discard Git changes", { title = "Git Status" })
            return
          end

          -- `git restore` does not remove untracked files; clean them after confirmation too.
          Snacks.picker.util.cmd({ "git", "clean", "-fd" }, function(_, clean_code)
            if clean_code ~= 0 then
              Snacks.notify.error("Could not remove untracked files", { title = "Git Status" })
              return
            end
            vim.schedule(function()
              picker:refresh()
              vim.cmd.checktime()
            end)
          end, { cwd = cwd })
        end,
        { cwd = cwd }
      )
    end
  )
end

local function discard_selected_git_changes()
  local picker = Snacks.picker.get({ source = "git_status" })[1]
  if not picker then
    return
  end

  local items = picker:selected({ fallback = true })
  if #items == 0 then
    return
  end
  local message = #items == 1 and ("Discard changes to `%s`?"):format(items[1].file)
    or ("Discard changes to %d files?"):format(#items)

  Snacks.picker.util.confirm(message, function()
    local pending = #items
    local function done(code)
      if code ~= 0 then
        Snacks.notify.error("Could not discard Git change", { title = "Git Status" })
      end
      pending = pending - 1
      if pending == 0 then
        vim.schedule(function()
          picker:refresh()
          vim.cmd.checktime()
        end)
      end
    end

    for _, item in ipairs(items) do
      local cwd = item.cwd or picker:cwd()
      local index_status = item.status:sub(1, 1)
      local command
      if item.status == "??" then
        command = { "git", "clean", "-f", "--", item.file }
      elseif index_status == "A" or index_status == "C" then
        command = { "git", "rm", "-f", "--", item.file }
      else
        command = { "git", "restore", "--source=HEAD", "--staged", "--worktree", "--", item.file }
        if item.rename then
          command[#command + 1] = item.rename
        end
      end
      Snacks.picker.util.cmd(command, function(_, code)
        done(code)
      end, { cwd = cwd })
    end
  end)
end

local function add_git_status_keymaps(picker)
  -- Function specs in `win.keys` can be normalized incorrectly by some Snacks
  -- versions, producing an empty lhs. Adding a buffer-local mapping after the
  -- window is created avoids this issue entirely.
  for _, win in ipairs({ picker.input.win, picker.list.win }) do
    vim.keymap.set({ "n", "i" }, "r", discard_selected_git_changes, {
      buffer = win.buf,
      nowait = true,
      desc = "Discard selected Git changes",
    })
    vim.keymap.set({ "n", "i" }, "R", discard_all_git_changes, {
      buffer = win.buf,
      nowait = true,
      desc = "Discard all Git changes",
    })
    vim.keymap.set({ "n", "i" }, "<Esc>", function()
      picker:close()
    end, {
      buffer = win.buf,
      nowait = true,
      desc = "Close Git Status",
    })
  end
end

local function add_explorer_resize_keymaps(picker)
  local function resize(delta)
    local win = vim.api.nvim_get_current_win()
    local width = vim.api.nvim_win_get_width(win)
    local min_width = math.max(1, math.floor(vim.o.columns * 0.15))
    local max_width = math.max(min_width, math.floor(vim.o.columns * 0.5))
    picker.layout.opts.layout.width = math.max(min_width, math.min(max_width, width + delta))
    vim.api.nvim_win_set_width(picker.layout.root.win, picker.layout.opts.layout.width)
    picker.layout:update()
    explorer_width = vim.api.nvim_win_get_width(win)
  end

  local keys = {
    shrink = { "<D-Left>", "<Home>", "<Esc>[99~", "<Esc>[9~", "<Esc>[1;9D" },
    grow = { "<D-Right>", "<End>", "<Esc>[100~", "<Esc>[00~", "<Esc>[1;9C" },
  }
  for _, win in ipairs({ picker.input.win, picker.list.win }) do
    vim.keymap.set({ "n", "i" }, "<C-b>", function()
      explorer_width = vim.api.nvim_win_get_width(picker.list.win.win)
      picker:close()
    end, { buffer = win.buf, nowait = true, desc = "Close explorer" })
    for _, lhs in ipairs(keys.shrink) do
      vim.keymap.set({ "n", "i" }, lhs, function()
        resize(-4)
      end, { buffer = win.buf, nowait = true, desc = "Shrink explorer" })
    end
    for _, lhs in ipairs(keys.grow) do
      vim.keymap.set({ "n", "i" }, lhs, function()
        resize(4)
      end, { buffer = win.buf, nowait = true, desc = "Grow explorer" })
    end
  end
end

local function close_picker(source)
  return function()
    if not Snacks then
      return
    end
    for _, picker in ipairs(Snacks.picker.get({ source = source })) do
      picker:close()
    end
  end
end

Modal.register("git_status", close_picker("git_status"))
Modal.register("git_branches", close_picker("git_branches"))

local function open_explorer()
  local min_width = math.max(1, math.floor(vim.o.columns * 0.15))
  local max_width = math.max(min_width, math.floor(vim.o.columns * 0.5))
  local width = math.max(min_width, math.min(max_width, explorer_width or 32))
  Snacks.explorer({
    cwd = LazyVim.root(),
    layout = {
      preset = "sidebar",
      preview = false,
      layout = { position = "left", width = width },
    },
  })
end

local function toggle_explorer()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer_width = vim.api.nvim_win_get_width(explorer.list.win.win)
    explorer:close()
  else
    open_explorer()
  end
end

vim.api.nvim_create_user_command("ExplorerToggle", toggle_explorer, { desc = "Toggle explorer" })

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<D-b>", toggle_explorer, mode = { "n", "i" }, desc = "Toggle explorer" },
      { "<C-b>", toggle_explorer, mode = { "n", "i" }, desc = "Toggle explorer" },
      { "<Esc>[98;9u", toggle_explorer, mode = { "n", "i" }, desc = "Toggle explorer" },
      { "<Esc>[98~", toggle_explorer, mode = { "n", "i" }, desc = "Toggle explorer" },
      {
        "<leader>e",
        function()
          local explorer = Snacks.picker.get({ source = "explorer" })[1]
          if explorer then
            explorer:focus()
          else
            open_explorer()
          end
        end,
        desc = "Focus explorer",
      },
      {
        "<leader>gs",
        open_git_status,
        desc = "List Git changes",
      },
      {
        "<leader>gb",
        open_git_branches,
        desc = "List Git branches",
      },
    },
    opts = {
      -- Show directories opened with `nvim .` in the left explorer instead of netrw.
      explorer = {},
      picker = {
        icons = {
          git = {
            added = "+",
            modified = "~",
            deleted = "-",
            renamed = ">",
            unmerged = "!",
            untracked = "?",
          },
        },
        sources = {
          explorer = {
            auto_close = false,
            format = format_explorer_item,
            on_show = add_explorer_resize_keymaps,

            hidden = true,
            ignored = false,

            layout = {
              preset = "sidebar",
              preview = false,
              layout = {
                position = "left",
                width = 32,
              },
            },
          },
          git_status = {
            -- First select changed files in a modal list; Enter opens the selected
            -- file's old and new versions side by side in Diffview.
            confirm = open_selected_diff,
            on_show = add_git_status_keymaps,
            layout = {
              preset = "select",
              layout = {
                footer = " r Restore  R Restore All  Esc Close ",
                footer_pos = "center",
              },
            },
            focus = "list",
            win = {
              input = {
                keys = {
                  ["r"] = { "git_restore", mode = { "n", "i" } },
                },
              },
              list = {
                keys = {
                  ["r"] = "git_restore",
                },
              },
            },
          },
        },
      },
    },
  },
}
