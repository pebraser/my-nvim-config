return {
  -- Theme
  {
    'Shatur/neovim-ayu',
    priority = 1000,
    init = function()
      vim.cmd [[colorscheme ayu]]
    end,
  },

  -- Rainbow delimiters
  { 'HiPhish/rainbow-delimiters.nvim' },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  -- Colored window separators
  {
    'nvim-zh/colorful-winsep.nvim',
    config = true,
    event = { 'WinLeave' },
  },

  -- Indent line
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
    dependencies = { 'HiPhish/rainbow-delimiters.nvim' },
    -- Makes current scope indent line colored based on rainbow_delimiters
    init = function()
      local highlight = {
        'RainbowRed',
        'RainbowYellow',
        'RainbowBlue',
        'RainbowOrange',
        'RainbowGreen',
        'RainbowViolet',
        'RainbowCyan',
      }
      local hooks = require 'ibl.hooks'
      -- create the highlight groups in the highlight setup hook, so they are reset
      -- every time the colorscheme changes
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        local colors = require 'ayu.colors'
        colors.generate(false)

        vim.api.nvim_set_hl(0, 'RainbowRed', { fg = colors.markup })
        vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = colors.func })
        vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = colors.entity })
        vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = colors.operator })
        vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = colors.string })
        vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = colors.constant })
        vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = colors.regexp })
      end)

      vim.g.rainbow_delimiters = { highlight = highlight }
      require('ibl').setup { scope = { highlight = highlight } }

      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    end,
  },

  {
    'jinh0/eyeliner.nvim',
    opts = {
      -- show highlights only after keypress
      highlight_on_key = true,

      -- dim all other characters if set to true (recommended!)
      dim = true,

      -- set the maximum number of characters eyeliner.nvim will check from
      -- your current cursor position; this is useful if you are dealing with
      -- large files: see https://github.com/jinh0/eyeliner.nvim/issues/41
      max_length = 9999,

      -- filetypes for which eyeliner should be disabled;
      -- e.g., to disable on help files:
      -- disabled_filetypes = {"help"}
      disabled_filetypes = {},

      -- buftypes for which eyeliner should be disabled
      -- e.g., disabled_buftypes = {"nofile"}
      disabled_buftypes = {},

      -- add eyeliner to f/F/t/T keymaps;
      -- see section on advanced configuration for more information
      default_keymaps = true,
    },
  },

  -- Line number theme
  {
    'mawkler/modicator.nvim',
    dependencies = 'ellisonleao/gruvbox.nvim', -- Add your colorscheme plugin here
    init = function()
      -- These are required for Modicator to work
      vim.o.cursorline = true
      vim.o.number = true
      vim.o.termguicolors = true
    end,
    opts = {
      -- Warn if any required option above is missing. May emit false positives
      -- if some other plugin modifies them, which in that case you can just
      -- ignore. Feel free to remove this line after you've gotten Modicator to
      -- work properly.
      show_warnings = true,
    },
  },

  -- Color visualization
  {
    'NvChad/nvim-colorizer.lua',
    event = 'BufReadPre',
    opts = {
      filetypes = { '*' },
      user_default_options = {
        names = true, -- "Name" codes like Blue or blue
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        RRGGBBAA = false, -- #RRGGBBAA hex codes
        AARRGGBB = false, -- 0xAARRGGBB hex codes
        rgb_fn = false, -- CSS rgb() and rgba() functions
        hsl_fn = false, -- CSS hsl() and hsla() functions
        css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        -- Highlighting mode.  'background'|'foreground'|'virtualtext'
        mode = 'background', -- Set the display mode
        -- Tailwind colors.  boolean|'normal'|'lsp'|'both'.  True is same as normal
        tailwind = false, -- Enable tailwind colors
        -- parsers can contain values used in |user_default_options|
        sass = { enable = false, parsers = { 'css' } }, -- Enable sass colors
        -- Virtualtext character to use
        virtualtext = '■',
        -- Display virtualtext inline with color
        virtualtext_inline = false,
        -- Virtualtext highlight mode: 'background'|'foreground'
        virtualtext_mode = 'foreground',
        -- update color values even if buffer is not focused
        -- example use: cmp_menu, cmp_docs
        always_update = false,
      },
      -- all the sub-options of filetypes apply to buftypes
      buftypes = {},
      -- Boolean | List of usercommands to enable
      user_commands = true, -- Enable all or some usercommands-- set to setup table
    },
  },
}
