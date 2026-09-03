local Modal = require("config.modal")
local stage = {}
local commit = {}
local last_messages = {}
local stage_highlight_ns = vim.api.nvim_create_namespace("git_ui_stage")

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Git" })
end

local function git(root, args, opts)
  local command = { "git" }
  vim.list_extend(command, args)
  local result = vim.system(command, {
    cwd = root,
    stdin = opts and opts.stdin or nil,
    text = true,
  }):wait()
  local output = vim.trim((result.stderr ~= "" and result.stderr) or result.stdout or "")
  return result.code == 0, output, result.code
end

local function git_root()
  local buffer_root = vim.b.git_ui_root
  if buffer_root and vim.fn.isdirectory(buffer_root) == 1 then
    return buffer_root
  end

  local name = vim.api.nvim_buf_get_name(0)
  local cwd = name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.fn.getcwd()
  local ok, root = git(cwd, { "rev-parse", "--show-toplevel" })
  if not ok then
    notify("Not inside a Git repository", vim.log.levels.ERROR)
    return
  end
  return root
end

local function split_null(output)
  if output == "" then
    return {}
  end
  return vim.split(output, "\0", { plain = true, trimempty = true })
end

local function unique_sorted(items)
  local seen = {}
  local result = {}
  for _, item in ipairs(items) do
    if item ~= "" and not seen[item] then
      seen[item] = true
      result[#result + 1] = item
    end
  end
  table.sort(result)
  return result
end

local function changed_files(root)
  local _, unstaged_output = git(root, { "diff", "--name-only", "-z" })
  local _, untracked_output = git(root, { "ls-files", "--others", "--exclude-standard", "-z" })
  local _, staged_output = git(root, { "diff", "--cached", "--name-only", "-z" })

  local unstaged = split_null(unstaged_output)
  vim.list_extend(unstaged, split_null(untracked_output))
  return unique_sorted(unstaged), unique_sorted(split_null(staged_output))
end

local function stage_is_open()
  return stage.left_win
    and vim.api.nvim_win_is_valid(stage.left_win)
    and stage.right_win
    and vim.api.nvim_win_is_valid(stage.right_win)
end

local function set_stage_lines(buf, win, title, files, empty_text, highlight)
  if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)) then
    return
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, #files > 0 and files or { empty_text })
  vim.bo[buf].modifiable = false
  vim.b[buf].git_ui_files = files
  vim.wo[win].winbar = string.format(" %s (%d) ", title, #files)
  vim.api.nvim_buf_clear_namespace(buf, stage_highlight_ns, 0, -1)
  for line = 0, #files - 1 do
    vim.api.nvim_buf_add_highlight(buf, stage_highlight_ns, highlight, line, 0, -1)
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  local cursor = vim.api.nvim_win_get_cursor(win)
  vim.api.nvim_win_set_cursor(win, { math.min(cursor[1], line_count), 0 })
end

local function refresh_stage()
  if not stage_is_open() then
    return
  end

  local unstaged, staged_files = changed_files(stage.root)
  set_stage_lines(
    stage.left_buf,
    stage.left_win,
    "Unstaged Changes",
    unstaged,
    "[No unstaged changes]",
    "DiagnosticError"
  )
  set_stage_lines(
    stage.right_buf,
    stage.right_win,
    "Staged Changes",
    staged_files,
    "[No staged changes]",
    "DiagnosticOk"
  )
end

local function stage_path(side)
  local buf = side == "left" and stage.left_buf or stage.right_buf
  local win = side == "left" and stage.left_win or stage.right_win
  if not (buf and win and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)) then
    return
  end
  local files = vim.b[buf].git_ui_files or {}
  return files[vim.api.nvim_win_get_cursor(win)[1]]
end

local function run_stage_action(args)
  local ok, output = git(stage.root, args)
  if not ok then
    notify(output ~= "" and output or "Git operation failed", vim.log.levels.ERROR)
    return false
  end
  refresh_stage()
  vim.cmd.checktime()
  return true
end

local function stage_current()
  local path = stage_path("left")
  if path then
    run_stage_action({ "add", "--", path })
  end
end

local function stage_all()
  run_stage_action({ "add", "--all" })
end

local function has_head(root)
  local ok = git(root, { "rev-parse", "--verify", "HEAD" })
  return ok
end

local function unstage_current()
  local path = stage_path("right")
  if not path then
    return
  end
  if has_head(stage.root) then
    run_stage_action({ "restore", "--staged", "--", path })
  else
    run_stage_action({ "rm", "--cached", "-f", "--", path })
  end
end

local function unstage_all()
  if has_head(stage.root) then
    run_stage_action({ "restore", "--staged", "." })
  else
    run_stage_action({ "rm", "--cached", "-r", "-f", "--", "." })
  end
end

local function close_stage()
  local left_win = stage.left_win
  local right_win = stage.right_win
  stage = {}
  for _, win in ipairs({ left_win, right_win }) do
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
end

local function configure_stage_buffer(buf, side)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "gitstatus"
  vim.bo[buf].modifiable = false
  vim.b[buf].git_ui_root = stage.root

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "r", refresh_stage, vim.tbl_extend("force", opts, { desc = "Refresh" }))
  vim.keymap.set("n", "<Esc>", close_stage, vim.tbl_extend("force", opts, { desc = "Close Git staging" }))

  if side == "left" then
    vim.keymap.set("n", "<CR>", stage_current, vim.tbl_extend("force", opts, { desc = "Stage file" }))
    vim.keymap.set("n", "<S-CR>", stage_all, vim.tbl_extend("force", opts, { desc = "Stage all files" }))
    vim.keymap.set("n", "<Right>", function()
      vim.api.nvim_set_current_win(stage.right_win)
    end, vim.tbl_extend("force", opts, { desc = "Focus staged files" }))
  else
    vim.keymap.set("n", "<CR>", unstage_current, vim.tbl_extend("force", opts, { desc = "Unstage file" }))
    vim.keymap.set("n", "<S-CR>", unstage_all, vim.tbl_extend("force", opts, { desc = "Unstage all files" }))
    vim.keymap.set("n", "<Left>", function()
      vim.api.nvim_set_current_win(stage.left_win)
    end, vim.tbl_extend("force", opts, { desc = "Focus unstaged files" }))
  end
end

local function open_git_add()
  if stage_is_open() then
    Modal.activate("git_add")
    vim.api.nvim_set_current_win(stage.left_win)
    refresh_stage()
    return
  end

  local root = git_root()
  if not root then
    return
  end
  Modal.activate("git_add")

  local total_width = math.min(120, math.max(30, vim.o.columns - 6))
  local pane_width = math.floor((total_width - 2) / 2)
  local height = math.min(24, math.max(8, vim.o.lines - 6))
  local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - (pane_width * 2 + 4)) / 2))

  stage.root = root
  stage.left_buf = vim.api.nvim_create_buf(false, true)
  stage.right_buf = vim.api.nvim_create_buf(false, true)
  stage.left_win = vim.api.nvim_open_win(stage.left_buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = pane_width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Unstaged Changes ",
    title_pos = "center",
    footer = " Enter Stage  Shift+Enter All  Esc Close ",
    footer_pos = "center",
  })
  stage.right_win = vim.api.nvim_open_win(stage.right_buf, false, {
    relative = "editor",
    row = row,
    col = col + pane_width + 2,
    width = pane_width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Staged Changes ",
    title_pos = "center",
    footer = " Enter Unstage  Shift+Enter All  Esc Close ",
    footer_pos = "center",
  })

  configure_stage_buffer(stage.left_buf, "left")
  configure_stage_buffer(stage.right_buf, "right")

  vim.wo[stage.left_win].cursorline = true
  vim.wo[stage.left_win].number = false
  vim.wo[stage.left_win].relativenumber = false
  vim.wo[stage.left_win].signcolumn = "no"

  vim.wo[stage.right_win].cursorline = true
  vim.wo[stage.right_win].number = false
  vim.wo[stage.right_win].relativenumber = false
  vim.wo[stage.right_win].signcolumn = "no"

  vim.api.nvim_set_current_win(stage.left_win)
  refresh_stage()
end

local function commit_is_open()
  return commit.win and vim.api.nvim_win_is_valid(commit.win) and commit.buf and vim.api.nvim_buf_is_valid(commit.buf)
end

local function branch_name(root)
  local ok, branch = git(root, { "branch", "--show-current" })
  return ok and branch ~= "" and branch or "detached HEAD"
end

local function staged_count(root)
  local _, files = git(root, { "diff", "--cached", "--name-only", "-z" })
  return #split_null(files)
end

local function update_commit_title()
  if not commit_is_open() then
    return
  end
  vim.api.nvim_win_set_config(commit.win, {
    title = " Git Commit | Branch: " .. branch_name(commit.root) .. " ",
    title_pos = "center",
  })
end

local function commit_message()
  local lines = vim.api.nvim_buf_get_lines(commit.buf, 0, -1, false)
  return vim.trim(table.concat(lines, "\n"))
end

local function create_commit()
  if not commit_is_open() then
    return
  end
  local message = commit_message()
  if message == "" then
    notify("Commit message cannot be empty", vim.log.levels.WARN)
    return
  end
  if staged_count(commit.root) == 0 then
    notify("There are no staged changes to commit", vim.log.levels.WARN)
    return
  end

  local ok, output = git(commit.root, { "commit", "-F", "-" }, { stdin = message .. "\n" })
  if not ok then
    notify(output ~= "" and output or "Commit failed", vim.log.levels.ERROR)
    return
  end

  last_messages[commit.root] = message
  vim.bo[commit.buf].modified = false
  update_commit_title()
  refresh_stage()
  vim.cmd.stopinsert()
  notify("Commit created")
end

local function push_commit()
  if not commit_is_open() then
    return
  end
  local branch = branch_name(commit.root)
  if branch == "detached HEAD" then
    notify("Cannot push from detached HEAD", vim.log.levels.ERROR)
    return
  end

  local has_upstream, upstream = git(commit.root, { "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" })
  local command = { "push" }
  local target = upstream
  if not has_upstream then
    local has_origin = git(commit.root, { "remote", "get-url", "origin" })
    if not has_origin then
      notify("No upstream or origin remote is configured", vim.log.levels.ERROR)
      return
    end
    command = { "push", "--set-upstream", "origin", branch }
    target = "origin/" .. branch
  end

  vim.ui.select({ "Push", "Cancel" }, {
    prompt = string.format("Push %s to %s?", branch, target),
  }, function(choice)
    if choice ~= "Push" then
      return
    end
    local ok, output = git(commit.root, command)
    if ok then
      notify("Push completed")
    else
      notify(output ~= "" and output or "Push failed", vim.log.levels.ERROR)
    end
  end)
end

local function close_commit()
  if commit_is_open() then
    vim.api.nvim_win_close(commit.win, true)
  end
  commit = {}
end

local function open_git_commit()
  if commit_is_open() then
    Modal.activate("git_commit")
    vim.api.nvim_set_current_win(commit.win)
    return
  end

  local root = git_root()
  if not root then
    return
  end
  Modal.activate("git_commit")

  local width = math.min(80, math.max(24, vim.o.columns - 4))
  local height = math.min(14, math.max(8, vim.o.lines - 6))
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Git Commit | Branch: " .. branch_name(root) .. " ",
    title_pos = "center",
    footer = " Ctrl/Cmd+S Commit  Ctrl/Cmd+P Push  Esc Close ",
    footer_pos = "center",
  })

  commit = { root = root, buf = buf, win = win }
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "gitcommit"
  vim.b[buf].git_ui_root = root
  vim.wo[win].wrap = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  local previous = last_messages[root]
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { previous or "" })
  vim.bo[buf].modified = false

  local opts = { buffer = buf, nowait = true, silent = true }
  for _, lhs in ipairs({ "<C-s>", "<D-s>" }) do
    vim.keymap.set({ "n", "i" }, lhs, create_commit, vim.tbl_extend("force", opts, { desc = "Create commit" }))
  end
  for _, lhs in ipairs({ "<C-p>", "<D-p>" }) do
    vim.keymap.set({ "n", "i" }, lhs, push_commit, vim.tbl_extend("force", opts, { desc = "Push commits" }))
  end
  vim.keymap.set({ "n", "i" }, "<Esc>", close_commit, vim.tbl_extend("force", opts, { desc = "Close commit window" }))
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd.startinsert()
end

Modal.register("git_add", close_stage)
Modal.register("git_commit", close_commit)

vim.api.nvim_create_user_command("GitAdd", open_git_add, { desc = "Open Git staging" })
vim.api.nvim_create_user_command("GitCommit", open_git_commit, { desc = "Open Git commit" })
vim.cmd([[cnoreabbrev <expr> ga getcmdtype() ==# ':' && getcmdline() ==# 'ga' ? 'GitAdd' : 'ga']])
vim.cmd([[cnoreabbrev <expr> gc getcmdtype() ==# ':' && getcmdline() ==# 'gc' ? 'GitCommit' : 'gc']])

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>ga", open_git_add, desc = "Git staging" },
      { "<leader>gc", open_git_commit, desc = "Git commit and push" },
    },
  },
}
