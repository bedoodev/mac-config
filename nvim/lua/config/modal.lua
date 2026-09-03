local M = { closers = {} }

function M.register(name, close)
  M.closers[name] = close
end

function M.activate(name)
  for modal, close in pairs(M.closers) do
    if modal ~= name then
      pcall(close)
    end
  end
end

function M.close_all()
  for _, close in pairs(M.closers) do
    pcall(close)
  end
end

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = vim.api.nvim_create_augroup("close_open_modals", { clear = true }),
  pattern = ":",
  callback = M.close_all,
})

return M
