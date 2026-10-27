return {
  -- Add these completion plugins
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp', priority = 1000 },
          { name = 'luasnip', priority = 750 },
          { name = 'buffer', priority = 500 },
          { name = 'path', priority = 250 },
        }),
        formatting = {
          format = function(entry, item)
            -- Show source in completion menu
            item.menu = ({
              nvim_lsp = '[LSP]',
              luasnip = '[Snippet]',
              buffer = '[Buffer]',
              path = '[Path]',
            })[entry.source.name]
            return item
          end,
        },
        experimental = {
          ghost_text = true, -- VSCode-like ghost text
        },
      })
    end,
  },
  
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim', 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      -- Get default capabilities with completion support
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      local function setup_tsgo()
        vim.lsp.config("tsgo", {
          capabilities = capabilities,
          -- nixpkgs' typescript 7 only ships `tsc`; prefer the project's tsgo when present
          cmd = function(dispatchers, config)
            local cmd = { "tsc", "--lsp", "--stdio" }
            if (config or {}).root_dir then
              local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin/tsgo")
              if vim.fn.executable(local_cmd) == 1 then
                cmd = { local_cmd, "--lsp", "--stdio" }
              end
            end
            return vim.lsp.rpc.start(cmd, dispatchers)
          end,
          settings = {
            typescript = {
              suggest = {
                includeCompletionsForModuleExports = true,
                includeAutomaticOptionalChainCompletions = true,
              },
              preferences = {
                includePackageJsonAutoImports = "auto",
                importModuleSpecifierPreference = "relative",
              },
            },
            javascript = {
              suggest = {
                includeCompletionsForModuleExports = true,
                includeAutomaticOptionalChainCompletions = true,
              },
              preferences = {
                includePackageJsonAutoImports = "auto",
                importModuleSpecifierPreference = "relative",
              },
            },
          },
        })
      end

      local function organize_imports(bufnr)
        local params = vim.lsp.util.make_range_params(0, "utf-8")
        params.context = { only = { "source.organizeImports" }, triggerKind = 1 }

        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        for client_id, res in pairs(result or {}) do
          local client = vim.lsp.get_client_by_id(client_id)
          for _, r in pairs(res.result or {}) do
            if r.edit then
              vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
            elseif r.command and client then
              client:exec_cmd(r.command, { bufnr = bufnr })
            end
          end
        end
      end

      local function setup_pyright()
        vim.lsp.config("pyright", {
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
              },
            },
          },
        })
      end

      local function setup_gopls()
        vim.lsp.config("gopls", {
          capabilities = capabilities,
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              staticcheck = true,
              gofumpt = true,
              completeUnimported = true, -- Auto-complete unimported packages
              usePlaceholders = true,
              matcher = "Fuzzy",
            },
          },
        })
      end

      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        update_in_insert = false,
        float = {
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- vim.lsp.config merges with lspconfig defaults; must run before servers are enabled
      vim.lsp.config("*", { capabilities = capabilities })
      setup_tsgo()
      setup_pyright()
      setup_gopls()

      require("mason").setup({})
      -- mason-lspconfig v2 has no `handlers`; it auto-enables installed servers
      require("mason-lspconfig").setup({
        ensure_installed = { 'lua_ls', 'pyright', 'gopls' },
        automatic_enable = { exclude = { 'ts_ls' } },
      })

      -- tsgo comes from nixpkgs (typescript 7), not mason
      vim.lsp.enable("tsgo")

      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('LspOrganizeImports', { clear = true }),
        desc = "Organize Imports on Save",
        callback = function(opts)
          local ft = vim.bo[opts.buf].filetype

          if (
            ft == 'typescriptreact' or
            ft == 'typescript' or
            ft == 'javascript' or
            ft == 'javascriptreact'
          ) then
            organize_imports(opts.buf)
          elseif ft == 'go' then
            organize_imports(opts.buf)
            -- Force format explicitly via gopls
            vim.lsp.buf.format({ async = false, bufnr = opts.buf })
          elseif ft == 'python' then
            vim.cmd("Black")
          end
        end
      })

      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics in loclist' })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
    end,
  }
}
