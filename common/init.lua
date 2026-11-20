-- init.lua — modern Lua config using lazy.nvim
-- Goal: preserve behavior, features and mappings from your Vimscript init.
-- Notes:
--  * Requires Neovim ≥ 0.11 (built-in LSP config, completion, tree-sitter).
--  * C/C++ LSP: clangd, only in projects with compile_commands.json.
--  * Telescope live_grep requires ripgrep.
--  * Tagbar needs ctags (prefer Universal Ctags).
--  * EditorConfig is built into Neovim, no plugin needed.
--  * telescope-frecency needs SQLite; plugin adds lua bindings automatically.

------------------------------------------------------------
-- Bootstrap lazy.nvim (plugin manager)
------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- Core options (ported 1:1 where sensible)
------------------------------------------------------------
local opt, g = vim.opt, vim.g
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

opt.showmatch = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.mouse = "c"            -- prefer cmdline mouse only (later overrides removed)
-- indentation default: 2 spaces; softtabstop -1 follows shiftwidth, so Tab
-- and >> always agree (per-language settings below override this)
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = -1
opt.expandtab = true
opt.autoindent = true
opt.number = true
opt.relativenumber = true
opt.clipboard = "unnamedplus"
opt.visualbell = true
opt.laststatus = 2

-- UI/Colors
opt.termguicolors = true
vim.cmd([[let g:dracula_italic=0]])

-- Statusline title
opt.title = true
opt.titlestring = "%<%F %M%=%l/%L - %p%%"
opt.titlelen = 70

-- Signs/gutter & ruler
opt.signcolumn = "yes:1"
opt.ruler = true

-- History & shada (viminfo)
opt.history = 1000
-- keep your explicit shada string
opt.shada = [[!,'1000,<100,s100,h,:10000,/10000]]

-- Misc
opt.backup = false
opt.foldcolumn = "0"
opt.modeline = true
opt.modelines = 10
opt.winminheight = 0
opt.switchbuf = "useopen"
opt.shortmess:append("Ic")
opt.path:append("**")
opt.backspace = { "indent", "eol", "start" }
opt.scrolloff = 2
opt.lazyredraw = true
opt.cursorline = true
opt.cursorcolumn = true

-- undo-config
opt.undofile = true
opt.undodir = os.getenv("HOME") .. "/.local/share/nvim/undo"

-- Cursor look
opt.guicursor = table.concat({
  "n-v-c:block-Cursor",
  "i:ver100-iCursor",
  "n-v-c:blinkon1000",
  "i:blinkon1000",
}, ",")

-- Wildmenu & ignore
opt.wildmenu = true
opt.wildignore = { "*.class", "*.o", "*.bak", "*.swp" }
opt.wildmode = "full"

-- Encoding / completion
opt.fileencodings = { "ucs-bom", "utf-8", "latin1" }
vim.opt.omnifunc = "syntaxcomplete#Complete"

-- Spell defaults used by some filetypes
opt.spelllang = { "de" }
vim.opt.spellsuggest = "best,10"

-- Leader & basic maps
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })
g.mapleader = " "

-- Keep search match centered
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- "Don't move" search on * and #, just highlight first
vim.keymap.set("n", "*", [[:let @/='\<<cword>\>'<CR>:set hls<CR>]], { silent = true, noremap = true })
vim.keymap.set("n", "#", [[:let @/='\<<cword>\>'<CR>:set hls<CR>]], { silent = true, noremap = true })

-- Command-line (bash-like) keys
vim.keymap.set("c", "<C-A>", "<Home>")
vim.keymap.set("c", "<C-E>", "<End>")
vim.keymap.set("c", "<C-K>", "<C-U>")
vim.keymap.set("c", "<C-P>", "<Up>")
vim.keymap.set("c", "<C-N>", "<Down>")

-- Quickfix nav
vim.keymap.set("n", "<Leader>cn", ":cnext<CR>")
vim.keymap.set("n", "<Leader>cp", ":cprev<CR>")

-- Tabpage nav on Shift-h/l
vim.keymap.set("n", "<S-h>", "gT")
vim.keymap.set("n", "<S-l>", "gt")

-- Smooth-ish scroll spam
vim.keymap.set("n", "<C-e>", "<C-e><C-e><C-e><C-e>")
vim.keymap.set("n", "<C-y>", "<C-y><C-y><C-y><C-y>")
vim.keymap.set("n", "<C-u>", "<C-y><C-y><C-y>")
vim.keymap.set("n", "<C-d>", "<C-e><C-e><C-e>")

-- Wrap arrows across lines
opt.whichwrap:append("<,>,[,],h,l")

-- Abbreviations (kept simple; see note below)
vim.cmd([[abbrev #d #define]])
vim.cmd([[abbrev #i #include <>]])
vim.cmd([[abbrev _if fprintf(stderr, "DEBUG [%s:%4d] - \n", __FILE__, __LINE__);]])

------------------------------------------------------------
-- Filetype-specific settings (autocmds)
------------------------------------------------------------
local aug = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

-- Restore last cursor position
local lastplace = aug("LastPlace", { clear = true })
au("BufReadPost", {
  group = lastplace,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end
})

-- Extra whitespace highlight
-- Trailing whitespace highlight (safe, no :syn pattern errors)
-- defined on ColorScheme: ":colorscheme" clears all highlight groups, so a
-- plain ":highlight" before it would be wiped (that was the old bug)
local wsgrp = vim.api.nvim_create_augroup('ExtraWhitespaceHL', { clear = true })
local function refresh_ws_hl()
  if vim.b._extra_ws_id then pcall(vim.fn.matchdelete, vim.b._extra_ws_id) end
  vim.b._extra_ws_id = vim.fn.matchadd('ExtraWhitespace', [[\s\+$\|\s\+\ze\t]])
end
vim.api.nvim_create_autocmd({ 'BufEnter','BufWinEnter','WinEnter','InsertLeave' }, {
  group = wsgrp,
  pattern = '*',
  callback = refresh_ws_hl,
})
vim.api.nvim_create_autocmd('ColorScheme', {
  group = wsgrp,
  callback = function()
    vim.api.nvim_set_hl(0, 'ExtraWhitespace', { bg = '#ff5555' })
    -- shade.nvim replacement: inactive windows a touch darker
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = '#21222c' })
  end,
})
vim.api.nvim_create_autocmd('InsertEnter', {
  group = wsgrp,
  pattern = '*',
  callback = function()
    if vim.b._extra_ws_id then pcall(vim.fn.matchdelete, vim.b._extra_ws_id); vim.b._extra_ws_id = nil end
  end,
})

-- Per-language tabs/indents
au("FileType", { pattern = "go", callback = function()
  vim.opt_local.expandtab = false
  vim.opt_local.tabstop = 8
  vim.opt_local.shiftwidth = 8
  vim.opt_local.softtabstop = 0
  vim.opt_local.autoindent = true
  vim.opt_local.cindent = true
end })

au("FileType", { pattern = { "python" }, callback = function()
  vim.opt_local.tabstop = 4
  vim.opt_local.softtabstop = 4
  vim.opt_local.shiftwidth = 4
  vim.opt_local.expandtab = true
  vim.opt_local.autoindent = true
  vim.opt_local.cindent = true
end })

au("FileType", { pattern = { "javascript", "html", "css" }, callback = function()
  vim.opt_local.tabstop = 2
  vim.opt_local.softtabstop = 2
  vim.opt_local.shiftwidth = 2
  vim.opt_local.expandtab = true
  vim.opt_local.autoindent = true
end })

au("FileType", { pattern = { "mail" }, callback = function()
  vim.opt_local.spelllang = { "de" }
  vim.opt_local.formatoptions:append("t")
  vim.opt_local.textwidth = 78
  vim.opt_local.cindent = false
  vim.opt_local.dictionary = "/usr/share/dict/words"
end })

au("FileType", { pattern = { "gitcommit" }, callback = function()
  vim.opt_local.spelllang = { "en" }
  vim.opt_local.fileformat = "unix"
  vim.opt_local.colorcolumn = "50,72"
  vim.opt_local.textwidth = 90
  vim.opt_local.expandtab = true
  vim.opt_local.cindent = false
end })

-- TeX: no auto/smart/cindent; width 90; tabs 4 expand
local texgrp = aug("tex_indent", { clear = true })
au("FileType", { group = texgrp, pattern = "tex", callback = function()
  vim.opt_local.fileformat = "unix"
  vim.opt_local.colorcolumn = "90"
  vim.opt_local.textwidth = 90
  vim.opt_local.expandtab = true
  vim.opt_local.tabstop = 4
  vim.opt_local.shiftwidth = 4
  vim.opt_local.indentexpr = ""
  vim.opt_local.formatexpr = ""
  vim.opt_local.autoindent = false
  vim.opt_local.smartindent = false
  vim.opt_local.cindent = false
  vim.opt_local.copyindent = false
  vim.opt_local.preserveindent = false
  vim.opt_local.formatoptions:remove({ 'c','r','o' })
end })

au("FileType", { pattern = { "ruby" }, callback = function()
  vim.opt_local.tabstop = 4
  vim.opt_local.shiftwidth = 4
  vim.opt_local.expandtab = true
end })

au({"BufNewFile","BufRead"}, {
  pattern = "/tmp/*mutt*",
  callback = function()
    vim.opt_local.autoindent = false
    vim.opt_local.filetype = "mail"
    vim.opt_local.wrapmargin = 0
    vim.opt_local.textwidth = 78
    vim.opt_local.number = false
    vim.opt_local.list = false
  end,
})

au("FileType", { pattern = { "c","cpp" }, callback = function()
  vim.opt_local.formatoptions:append("ro")
  vim.opt_local.dictionary = vim.fn.expand("$HOME/.vim/c_dictionary")
  vim.opt_local.textwidth = 78
  vim.opt_local.tabstop = 8
  vim.opt_local.shiftwidth = 8
  vim.opt_local.softtabstop = 0   -- kernel style: Tab inserts one real tab
  vim.opt_local.expandtab = false
  vim.opt_local.cindent = true
end })

au("FileType", { pattern = { "perl" }, callback = function()
  vim.opt_local.smartindent = true
  vim.opt_local.tabstop = 4
  vim.opt_local.shiftwidth = 4
end })

au("FileType", { pattern = { "markdown" }, callback = function()
  vim.opt_local.spell = true
end })

au("FileType", { pattern = { "make", "automake" }, callback = function()
  vim.opt_local.expandtab = false
  vim.opt_local.tabstop = 8
  vim.opt_local.shiftwidth = 8
  vim.opt_local.softtabstop = 0
end })

-- Spell toggle cycling: nospell → de_de → en_us (highlighting stays on)
local myLangList = { 'nospell', 'de_de', 'en_us' }
local myLang = 0
local function MySpellLang()
  myLang = (myLang + 1) % #myLangList
  local cur = myLangList[myLang + 1]
  if cur == 'nospell' then
    vim.opt_local.spell = false
  else
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { cur }
  end
  vim.notify('Spell language: ' .. cur)
end
vim.keymap.set({"n","i"}, "<F7>", function()
  if vim.fn.mode() == 'i' then vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false) end
  MySpellLang()
end, { silent = true })

-- Clipboard yanks/pastes
vim.keymap.set({"n","v"}, "<leader>y", "+y")
vim.keymap.set("n", "<leader>p", "+p")
vim.keymap.set("n", "<leader>P", "+P")
vim.keymap.set("v", "<leader>p", "+p")
vim.keymap.set("v", "<leader>P", "+P")

-- Terminal in current file dir
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("cd %:p:h")
  vim.cmd("terminal")
  vim.cmd("startinsert")
end)

-- F2: Dateien im aktuellen Projekt/Working Dir
vim.keymap.set({"n","i"}, "<F2>", function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false)
  end
  require('fzf-lua').files()
end, { silent = true })

-- F3: Dateien ab $HOME
vim.keymap.set({"n","i"}, "<F3>", function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false)
  end
  require('fzf-lua').files({ cwd = vim.fn.expand('~') })
end, { silent = true })

-- F4: Live-Grep (ripgrep)
vim.keymap.set({"n","i"}, "<F4>", function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false)
  end
  require('fzf-lua').live_grep()
end, { silent = true })

vim.keymap.set({"n","i"}, "<F5>", function()
  if vim.fn.mode() == 'i' then vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false) end
  vim.cmd("TagbarToggle")
end)

vim.keymap.set({"n","i"}, "<F6>", function()
  if vim.fn.mode() == 'i' then vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false) end
  vim.cmd("Telescope file_browser")
end)
-- F8
vim.keymap.set({"n","i"}, "<F8>", function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false)
  end
  require('fzf-lua').builtin()
end, { silent = true })

vim.keymap.set({"n","i"}, "<F9>", function()
  if vim.fn.mode() == 'i' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-o>',true,false,true), 'n', false)
  end
  require('fzf-lua').buffers()
end, { silent = true })

vim.keymap.set("n", "<F11>", ":resize -5<CR>", { silent = true })
vim.keymap.set("n", "<F12>", ":resize +5<CR>", { silent = true })


-- Telescope leader bindings
vim.keymap.set("n", "<leader>ff", function() require('telescope.builtin').find_files() end)
vim.keymap.set("n", "<leader>fg", function() require('telescope.builtin').live_grep() end)
vim.keymap.set("n", "<leader>fb", function() require('telescope.builtin').buffers() end)
vim.keymap.set("n", "<leader>fh", function() require('telescope.builtin').help_tags() end)

------------------------------------------------------------
-- Plugin specs
------------------------------------------------------------
require('lazy').setup({
  -- Core deps
  { 'nvim-lua/plenary.nvim' },

  -- Colorscheme
  { 'dracula/vim', name = 'dracula' },

  -- Statusline
  { 'nvim-lualine/lualine.nvim', config = function()
      require('lualine').setup({
        options = {
          icons_enabled = false,
          component_separators = '|',
          section_separators = '',
          refresh = { statusline = 2000, tabline = 2000, winbar = 2000 },
        },
        sections = {
          lualine_c = { { 'filename', path = 3 } },
        },
      })
    end },

  -- Git signs
  { 'lewis6991/gitsigns.nvim', config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '│' }, change = { text = '│' }, delete = { text = '_' },
          topdelete = { text = '‾' }, changedelete = { text = '~' }, untracked = { text = '┆' },
        },
        signcolumn = true,
        numhl = false, linehl = false, word_diff = false,
        watch_gitdir = { follow_files = true },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = { virt_text = true, virt_text_pos = 'eol', delay = 1000, ignore_whitespace = false },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        sign_priority = 1, update_debounce = 100,
        max_file_length = 40000,
        preview_config = { border = 'single', style = 'minimal', relative = 'cursor', row = 0, col = 1 },
      })
    end },

  -- Telescope + extensions
  { 'nvim-telescope/telescope.nvim', branch = 'master', dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('telescope').setup({

      defaults = {
        sort_lastused = true,
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.5,
          },
        },
        sorting_strategy = "ascending",
        theme = 'dropdown',
        file_ignore_patterns = { '%.png', '%.svg', '%.webm', '%.pdf' },
      },
        pickers = { buffers = { sort_lastused = true, theme = 'dropdown' } },
        extensions = {
          file_browser = {
            theme = 'dropdown', hijack_netrw = true,
            mappings = { i = {}, n = {} },
          },
          frecency = { sort_by = 'frecency' },
        },
      })
      pcall(require('telescope').load_extension, 'file_browser')
      pcall(require('telescope').load_extension, 'frecency')
      -- F1 -> frecency
      vim.keymap.set('n', '<F1>', ':Telescope frecency<CR>', { noremap = true, silent = true })
    end },
  { 'nvim-telescope/telescope-file-browser.nvim' },
  { 'nvim-telescope/telescope-frecency.nvim', dependencies = { 'kkharji/sqlite.lua' } },
  { 'kkharji/sqlite.lua' },

  -- Leap. Moved from GitHub to Codeberg in 2025 (the GitHub repo is now
  -- empty). flit.nvim is discontinued; its f/F/t/T live in Leap itself now
  -- (:help leap-ft), set up below the same way flit worked.
  { url = 'https://codeberg.org/andyg/leap.nvim', name = 'leap.nvim', config = function()
      vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
      vim.api.nvim_set_hl(0, 'LeapMatch', { fg = '#ffffff', bold = false, nocombine = true })
      local leap = require('leap')
      leap.opts.safe_labels = ''

      -- the former default mappings, spelled out (add_default_mappings is deprecated);
      -- remap = true is required, otherwise the <Plug> keys never expand
      vim.keymap.set({ 'n', 'x', 'o' }, 's',  '<Plug>(leap-forward)', { remap = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'S',  '<Plug>(leap-backward)', { remap = true })
      vim.keymap.set({ 'x', 'o' },      'x',  '<Plug>(leap-forward-next-to)', { remap = true })
      vim.keymap.set({ 'x', 'o' },      'X',  '<Plug>(leap-backward-next-to)', { remap = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'gs', '<Plug>(leap-from-window)', { remap = true })
      -- leader-space forward, leader-esc backward
      vim.keymap.set({ 'n', 'x', 'o' }, '<leader><space>', function() leap.leap({}) end)
      vim.keymap.set({ 'n', 'x', 'o' }, '<leader><esc>', function() leap.leap({ backward = true }) end)

      -- f/F/t/T as flit had them: one character, autojump, multiline,
      -- repeat with the same key (clever-f style)
      local function ft(kwargs)
        leap.leap(vim.tbl_deep_extend('keep', kwargs, {
          inputlen = 1,
          inclusive = true,
          opts = { labels = '', safe_labels = vim.fn.mode(1):match('no?') and '' or nil },
        }))
      end
      local clever = require('leap.user').with_traversal_keys
      local clever_f, clever_t = clever('f', 'F'), clever('t', 'T')
      vim.keymap.set({ 'n', 'x', 'o' }, 'f', function() ft({ opts = clever_f }) end)
      vim.keymap.set({ 'n', 'x', 'o' }, 'F', function() ft({ backward = true, opts = clever_f }) end)
      vim.keymap.set({ 'n', 'x', 'o' }, 't', function() ft({ offset = -1, opts = clever_t }) end)
      vim.keymap.set({ 'n', 'x', 'o' }, 'T', function() ft({ backward = true, offset = 1, opts = clever_t }) end)
    end },

  -- Tagbar (project moved to preservim)
  { 'preservim/tagbar', cmd = 'TagbarToggle' },

  -- FZF-Lua (fzf-UI für Neovim)
  {
    'ibhagwan/fzf-lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- optional, nur für hübsche Icons
      -- optional: installiert das fzf-Binary via Plugin statt Systempaket
      -- { 'junegunn/fzf', build = './install --bin' },
    },
    config = function()
      require('fzf-lua').setup({})
    end,
  },



  {
  "debugloop/telescope-undo.nvim",
  dependencies = { -- note how they're inverted to above example
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  keys = {
    { -- lazy style key map
      "<leader>u",
      "<cmd>Telescope undo<cr>",
      desc = "undo history",
    },
  },
  opts = {
    -- don't use `defaults = { }` here, do this in the main telescope spec
    extensions = {
      undo = {
        -- telescope-undo.nvim config, see below
      },
      -- no other extensions here, they can have their own spec too
    },
  },
  config = function(_, opts)
    -- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
    -- configs for us. We won't use data, as everything is in it's own namespace (telescope
    -- defaults, as well as each extension).
    require("telescope").setup(opts)
    require("telescope").load_extension("undo")
    vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
  end,
},






}, {
  ui = { border = 'rounded' },
  performance = {
    rtp = {
      -- Debian ships the Neovim tree-sitter parsers (markdown, lua, vim, ...)
      -- in /usr/lib/nvim/parser; lazy's rtp reset would drop that directory
      -- and the built-in markdown ftplugin then fails to start its parser.
      paths = { '/usr/lib/nvim' },
    },
  },
})

------------------------------------------------------------
-- Colorscheme & highlights
------------------------------------------------------------
vim.cmd("colorscheme dracula")
vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#2d2f3f' })
vim.api.nvim_set_hl(0, 'CursorColumn', { bg = '#2d2f3f' })

------------------------------------------------------------
-- Language-specific globals (c/perl/python highlighting)
------------------------------------------------------------
vim.g.c_space_errors = 1
vim.g.c_ansi_typedefs = 1
vim.g.c_ansi_constants = 1
vim.g.c_no_bracket_error = 1
vim.g.c_no_curly_error = 1
vim.g.c_comment_strings = 1
vim.g.c_gnu = 1
vim.g.python_highlight_all = 1
vim.g.perl_extended_vars = 1


-- Grep unter Cursor
vim.keymap.set("n", "<leader>*", function()
  require('fzf-lua').grep_cword()
end, { silent = true })

------------------------------------------------------------
-- Tree-sitter: highlighting from the parsers Neovim/Debian ship
-- (/usr/lib/nvim/parser: c, lua, vim, vimdoc, query, markdown); filetypes
-- without a parser keep the classic syntax highlighting
------------------------------------------------------------
au("FileType", {
  group = aug("TreesitterStart", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if lang and vim.treesitter.language.add(lang) then
      pcall(vim.treesitter.start, ev.buf, lang)
    end
  end,
})

------------------------------------------------------------
-- LSP (built in since 0.11): clangd for C/C++
-- Only starts where a compile database exists, so random C files and an
-- unconfigured kernel tree stay quiet. Kernel: make, then
--   scripts/clang-tools/gen_compile_commands.py
------------------------------------------------------------
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--header-insertion=never" },
  filetypes = { "c", "cpp" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "compile_commands.json", "compile_flags.txt", ".clangd" })
    if root then on_dir(root) end
  end,
})
vim.lsp.enable("clangd")

vim.diagnostic.config({
  virtual_text = { current_line = true },
  severity_sort = true,
  float = { border = "rounded" },
})

opt.completeopt = { "menu", "menuone", "noselect", "popup" }

-- Defaults from Neovim: K hover, grn rename, gra code action, grr references,
-- gri implementation, gO symbols, [d ]d diagnostics, <C-s> signature help
au("LspAttach", {
  group = aug("LspAttachLocal", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "LSP definition" })
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { buffer = ev.buf, desc = "Diagnostic" })
  end,
})
