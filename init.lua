vim.cmd("language en_US")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- colorscheme
    { 
        "ellisonleao/gruvbox.nvim", 
        priority = 1000,
        config = function ()
            require("gruvbox").setup({
                contrast = "hard"
            })
            vim.cmd([[colorscheme gruvbox]])
        end,
    },
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.6',
        dependencies = {'nvim-lua/plenary.nvim'},
        config = function()
            require('telescope').setup({

            })
        end
    },
    {
        'nvim-treesitter/nvim-treesitter',
        version = false,
        build = ":TSUpdate",
        init = function(plugin)
            require("lazy.core.loader").add_to_rtp(plugin)
            require("nvim-treesitter.query_predicates")
        end,
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = {"go", "svelte", "javascript", "typescript", "c", "lua", "vim", "vimdoc", "query"},
                sync_install = false,
                auto_install = true,
                autopairs = {enable = true},
                highlight = {enable = true}
            })
        end
    },
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        lazy = true,
        config = false,
        init = function()
            vim.g.lsp_zero_extend_cmp = 0
            vim.g.lsp_zero_extend_lspconfig = 0
        end,
    },
    {
        'williamboman/mason.nvim',
        lazy = false,
        config = true,
    },
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            {'L3MON4D3/LuaSnip'},
        },
        config = function()
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_cmp()

            local cmp = require('cmp')
            local cmp_action = lsp_zero.cmp_action()

            cmp.setup({
                formatting = lsp_zero.cmp_format({details = true}),
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                }),
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
            })
        end
    },
    {
        'neovim/nvim-lspconfig',
        cmd = 'LspInfo',
        event = {'BufReadPre', 'BufNewFile'},
        dependencies = {
            {'hrsh7th/cmp-nvim-lsp'},
            {'williamboman/mason-lspconfig.nvim'},
        },
        config = function()
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            lsp_zero.on_attach(function(client, bufnr)
                local opts = {buffer = bufnr, remap = false}

                vim.keymap.set('n', 'gd', "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
                vim.keymap.set('n', '<leader>vs', "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", opts)
                vim.keymap.set('n', '<leader>bs', "<cmd>belowright split | lua vim.lsp.buf.definition()<CR>", opts)

                vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
                vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'H', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, opts)
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                vim.keymap.set({'n', 'v'}, '<leader>vca', vim.lsp.buf.code_action, opts)
            end)

            require('mason-lspconfig').setup({
                ensure_installed = {"tsserver", "gopls", "svelte"},
                handlers = {
                    function(server_name)
                        require('lspconfig')[server_name].setup({})
                    end,

                    lua_ls = function()
                        local lua_opts = lsp_zero.nvim_lua_ls()
                        require('lspconfig').lua_ls.setup(lua_opts)
                    end,
                }
            })
        end
    }
})



------------
--Settings--
------------


vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.opt.modelines = 0

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.scrolloff = 16

vim.opt.colorcolumn = "80"

-- Keymap --
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- ColorScheme --
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

-- Telescope --
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
