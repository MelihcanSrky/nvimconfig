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
        'comfysage/evergarden',
        lazy = false,
        priority = 1000,
        opts = {
            transparent_background = false,
            contrast_dark = 'medium'
        },
        config = function()
            require("evergarden").setup({
            })
            vim.cmd([[colorscheme evergarden]])
        end,
    },
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.6',
        dependencies = { 'nvim-lua/plenary.nvim', "nvim-tree/nvim-web-devicons", },
        config = function()
            require('telescope').setup({
            })
        end
    },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            { "windwp/nvim-ts-autotag" }
        },
        version = false,
        build = ":TSUpdate",
        init = function(plugin)
            require("lazy.core.loader").add_to_rtp(plugin)
            require("nvim-treesitter.query_predicates")
        end,
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = { "vue", "go", "svelte", "angular", "javascript", "typescript", "c", "lua", "vim", "vimdoc", "query" },
                sync_install = false,
                auto_install = true,
                autopairs = { enable = true },
                highlight = { enable = true }
            })
            require('nvim-ts-autotag').setup({
                opts = {
                    -- Defaults
                    enable_close = true,          -- Auto close tags
                    enable_rename = true,         -- Auto rename pairs of tags
                    enable_close_on_slash = false -- Auto close on trailing </
                },
                per_filetype = {
                    ["html"] = {
                        enable_close = true
                    }
                }
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
            {
                'L3MON4D3/LuaSnip',
                dependencies = {
                    "rafamadriz/friendly-snippets",
                },
                config = function()
                    require("luasnip/loaders/from_vscode").lazy_load()
                    require("luasnip").filetype_extend("typescriptreact", { "react" })
                end
            },
        },
        config = function()
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_cmp()

            local cmp = require('cmp')
            local cmp_action = lsp_zero.cmp_action()

            local luasnip = require('luasnip')

            -- Load friendly-snippets

            cmp.setup({
                formatting = lsp_zero.cmp_format({ details = true, maxWidth = 80 }),
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                    ['<CR>'] = cmp.mapping.confirm { select = true }
                }),
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
            })
        end
    },
    {
        'neovim/nvim-lspconfig',
        cmd = 'LspInfo',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            servers = {
                tailwindcss = {},
            },
        },
        dependencies = {
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'williamboman/mason-lspconfig.nvim' },
        },
        config = function()
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            lsp_zero.on_attach(function(client, bufnr)
                local opts = { buffer = bufnr, remap = false }

                vim.keymap.set('n', 'gd', "<cmd>lua vim.lsp.buf.definition()<CR>", opts)


                vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
                vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
                vim.keymap.set('n', '<leader>e', function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'H', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, opts)
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                vim.keymap.set({ 'n', 'v' }, '<leader>vca', vim.lsp.buf.code_action, opts)
            end)

            require('mason-lspconfig').setup({
                ensure_installed = { "tsserver", "gopls", "svelte", "volar", "angularls" },
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

            require('lspconfig').svelte.setup {
                filetypes = { "svelte" },
                on_attach = function(client, bufnr)
                    if client.name == 'svelte' then
                        vim.api.nvim_create_autocmd("BufWritePost", {
                            pattern = { "*.js", "*.ts", "*.svelte" },
                            callback = function(ctx)
                                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
                            end,
                        })
                    end
                    if vim.bo[bufnr].filetype == "svelte" then
                        vim.api.nvim_create_autocmd("BufWritePost", {
                            pattern = { "*.js", "*.ts", "*.svelte" },
                            callback = function(ctx)
                                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
                            end,
                        })
                    end
                end
            }
        end
    },
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("nvim-tree").setup {
                view = {
                    width = 30
                }
            }
        end,
    },
    {
        'windwp/nvim-autopairs',
        config = function()
            require("nvim-autopairs").setup {
                check_ts = true
            }
        end
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = 'evergarden',
                    sections = {
                        lualine_c = {
                            'filename',
                            file_status = true,
                            path = 2
                        }
                    }
                }
            }
        end
    },
    {
        "fatih/vim-go",
        config = function()
            -- vim.g['go_gopls_enabled'] = 0
            -- vim.g['go_code_completion_enabled'] = 0
            -- vim.g['go_fmt_autosave'] = 0
            -- vim.g['go_imports_autosave'] = 0
            -- vim.g['go_mod_fmt_autosave'] = 0
            -- vim.g['go_doc_keywordprg_enabled'] = 0
            -- vim.g['go_def_mapping_enabled'] = 0
            -- vim.g['go_textobj_enabled'] = 0
            -- vim.g['go_list_type'] = 'quickfix'
        end,
    },
    {
        "numToStr/Comment.nvim",
        config = function()
            require('Comment').setup({
                opleader = {
                    ---Block-comment keymap
                    block = '<Nop>',
                },
            })
        end
    },
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            require("bufferline").setup {}
        end
    },
    {
        'NvChad/nvim-colorizer.lua',
        opts = {
            user_default_options = {
                tailwind = true,
            },
        },
    },
    {
        "elentok/format-on-save.nvim",
        config = function()
            local formatters = require("format-on-save.formatters")
            require("format-on-save").setup({
                exclude_path_patterns = {
                    "/node_modules/",
                    ".local/share/nvim/lazy",
                },
                formatter_by_ft = {
                    css = formatters.lsp,
                    html = formatters.lsp,
                    java = formatters.lsp,
                    svelte = formatters.lsp,
                    json = formatters.lsp,
                    lua = formatters.lsp,
                    markdown = formatters.prettierd,
                    javascript = formatters.lsp,
                    openscad = formatters.lsp,
                    python = formatters.lsp,
                    rust = formatters.lsp,
                    scad = formatters.lsp,
                    scss = formatters.lsp,
                    sh = formatters.lsp,
                    terraform = formatters.lsp,
                    typescript = formatters.lsp,
                    typescriptreact = formatters.lsp,
                    -- Optional: fallback formatter to use when no formatters match the current filetype
                    fallback_formatter = {
                        formatters.remove_trailing_whitespace,
                        formatters.remove_trailing_newlines,
                        formatters.prettierd,
                    }
                },
                -- run_with_sh = false,
            })
        end
    },
    {
        {
            "tiagovla/scope.nvim",
            config = function()
                require("scope").setup({})
            end
        }
    }
})

------------
--Settings--
------------


vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>bd", ":bd<CR>")

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

vim.keymap.set("n", "<A-1>", ":NvimTreeToggle<CR>")

vim.keymap.set('n', '<leader>vs', "<cmd>vsplit<CR>")
vim.keymap.set('n', '<leader>hs', "<cmd>split<CR>")

vim.keymap.set("x", "<leader>p", "\"_dP")
vim.keymap.set("t", "<F12>", "<C-\\><C-n>")
-- ColorScheme --
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

-- Telescope --
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)

-- BufferLine --
vim.keymap.set('n', '<leader>mm', '<CMD>BufferLinePick<CR>')
vim.keymap.set('n', '<leader>mn', '<CMD>BufferLineCycleNext<CR>')
vim.keymap.set('n', '<leader>mp', '<CMD>BufferLineCyclePrev<CR>')
vim.keymap.set('n', '<leader>cp', '<CMD>BufferLinePickClose<CR>')
vim.keymap.set('n', '<leader>tn', ':tabnext<CR>')
vim.keymap.set('n', '<leader>tp', ':tabprevious<CR>')
