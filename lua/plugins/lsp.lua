return {
  -- LSP Configuration & Plugins
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      -- 'williamboman/mason-lspconfig.nvim',
      -- 'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { 'folke/neodev.nvim', opts = {} },
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- Find references for the word under your cursor.
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

          -- Opens a popup that displays documentation about the word under your cursor
          --  See `:help K` for why this keymap.
          map('K', vim.lsp.buf.hover, 'Hover Documentation')

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      require('neodev').setup()
      require('lspconfig').lua_ls.setup {
        capabilities = capabilities,
      }
      require('lspconfig').marksman.setup {
        capabilities = capabilities,
      }
      require('lspconfig').hyprls.setup {
        capabilities = capabilities,
        -- For hyprland file detection
        vim.filetype.add {
          pattern = { ['.*/hypr/.*%.conf'] = 'hyprlang' },
        },
      }
      require('lspconfig').html.setup {
        capabilities = capabilities,
      }
      require('lspconfig').cssls.setup {
        capabilities = capabilities,
      }
      require('lspconfig').jsonls.setup {
        capabilities = capabilities,
      }
      require('lspconfig').clangd.setup {
        capabilities = capabilities,
      }
      require('lspconfig').rust_analyzer.setup {
        capabilities = capabilities,
      }
      require('lspconfig').dartls.setup {
        capabilities = capabilities,
      }
    end,
  },

  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },

          -- If you prefer more traditional completion keymaps,
          -- you can uncomment the following lines
          --['<CR>'] = cmp.mapping.confirm { select = true },
          --['<Tab>'] = cmp.mapping.select_next_item(),
          --['<S-Tab>'] = cmp.mapping.select_prev_item(),

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete {},

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  -- Dynamic helper documentation display on floating windows
  {
    'Dan7h3x/signup.nvim',
    branch = 'main',
    opts = {
      -- Your configuration options here
      silent = false,
      number = true,
      icons = {
        parameter = '',
        method = '󰡱',
        documentation = '󱪙',
      },
      colors = {
        -- parameter = '#86e1fc',
        -- method = '#c099ff',
        -- documentation = '#4fd6be',
        -- default_value = '#a80888',
      },
      active_parameter_colors = {
        -- bg = '#86e1fc',
        -- fg = '#1a1a1a',
      },
      border = 'solid',
      winblend = 10,
      auto_close = true,
      trigger_chars = { '(', ',' },
      max_height = 10,
      max_width = 40,
      floating_window_above_cur_line = true,
      preview_parameters = true,
      debounce_time = 30,
      dock_toggle_key = '<Leader>sd',
      toggle_key = '<C-k>',
      dock_mode = {
        enabled = false,
        position = 'bottom',
        height = 3,
        padding = 1,
      },
      render_style = {
        separator = true,
        compact = true,
        align_icons = true,
      },
    },
    config = function(_, opts)
      require('signup').setup(opts)
    end,
  },

  -- Better diagnostic messages
  -- {
  --   'rachartier/tiny-inline-diagnostic.nvim',
  --   event = 'VeryLazy', -- Or `LspAttach`
  --   priority = 1000, -- needs to be loaded in first
  --   config = function()
  --     require('tiny-inline-diagnostic').setup {
  --       preset = 'modern', -- Can be: "modern", "classic", "minimal", "powerline", ghost", "simple", "nonerdfont", "amongus"
  --       hi = {
  --         error = 'DiagnosticError',
  --         warn = 'DiagnosticWarn',
  --         info = 'DiagnosticInfo',
  --         hint = 'DiagnosticHint',
  --         arrow = 'NonText',
  --         background = 'CursorLine', -- Can be a highlight or a hexadecimal color (#RRGGBB)
  --         mixing_color = 'None', -- Can be None or a hexadecimal color (#RRGGBB). Used to blend the background color with the diagnostic background color with another color.
  --       },
  --       options = {
  --         -- Show the source of the diagnostic.
  --         show_source = false,
  --
  --         -- Use your defined signs in the diagnostic config table.
  --         use_icons_from_diagnostic = false,
  --
  --         -- Add messages to the diagnostic when multilines is enabled
  --         add_messages = true,
  --
  --         -- Throttle the update of the diagnostic when moving cursor, in milliseconds.
  --         -- You can increase it if you have performance issues.
  --         -- Or set it to 0 to have better visuals.
  --         throttle = 20,
  --
  --         -- The minimum length of the message, otherwise it will be on a new line.
  --         softwrap = 30,
  --
  --         -- If multiple diagnostics are under the cursor, display all of them.
  --         multiple_diag_under_cursor = false,
  --
  --         -- Enable diagnostic message on all lines.
  --         multilines = false,
  --
  --         -- Show all diagnostics on the cursor line.
  --         show_all_diags_on_cursorline = false,
  --
  --         -- Enable diagnostics on Insert mode. You should also se the `throttle` option to 0, as some artefacts may appear.
  --         enable_on_insert = false,
  --
  --         overflow = {
  --           -- Manage the overflow of the message.
  --           --    - wrap: when the message is too long, it is then displayed on multiple lines.
  --           --    - none: the message will not be truncated.
  --           --    - oneline: message will be displayed entirely on one line.
  --           mode = 'wrap',
  --         },
  --
  --         -- Format the diagnostic message.
  --         -- Example:
  --         -- format = function(diagnostic)
  --         --     return diagnostic.message .. " [" .. diagnostic.source .. "]"
  --         -- end,
  --         format = nil,
  --
  --         --- Enable it if you want to always have message with `after` characters length.
  --         break_line = {
  --           enabled = false,
  --           after = 30,
  --         },
  --
  --         virt_texts = {
  --           priority = 2048,
  --         },
  --
  --         -- Filter by severity.
  --         severity = {
  --           vim.diagnostic.severity.ERROR,
  --           vim.diagnostic.severity.WARN,
  --           vim.diagnostic.severity.INFO,
  --           vim.diagnostic.severity.HINT,
  --         },
  --
  --         -- Overwrite events to attach to a buffer. You should not change it, but if the plugin
  --         -- does not works in your configuration, you may try to tweak it.
  --         overwrite_events = nil,
  --       },
  --     }
  --   end,
  -- },

  -- Eww development (yuck)
  { 'elkowar/yuck.vim' },

  -- Easy time with (), [] and {}: Parinfer
  { 'gpanders/nvim-parinfer' },
}
