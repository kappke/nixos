vim.o.tabstop = 2
vim.o.expandtab = true
vim.o.softtabstop = 2
vim.o.shiftwidth = 2

vim.o.relativenumber = true
vim.o.wrap = false

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

vim.g.python3_host_prog = '~/.local/venv/nvim/bin/python'

vim.o.wrap = true
vim.o.linebreak = true
vim.o.breakindent = true

-- Disable arrow keys in Normal, Insert, and Visual modes
local modes = { 'n', 'i', 'v' }
local keys = { '<Up>', '<Down>', '<Left>', '<Right>' }

for _, mode in ipairs(modes) do
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, '<nop>', { noremap = true, silent = true })
  end
end
