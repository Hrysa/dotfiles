-- echo "{{ .chezmoi.os }}"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.updatetime = 200
vim.g.mapleader = " "

if vim.lsp.inlay_hint then
    vim.lsp.inlay_hint.enable(true)
end

local key = vim.keymap.set
key("i", "jj", "<esc>")
key({ "n", "i", "v" }, "<C-s>", "<ESC>:w<CR>")

-- LSP 核心操作
key("n", "gd", vim.lsp.buf.definition)
key("n", "gr", vim.lsp.buf.references)
key("n", "K", vim.lsp.buf.hover)
key({ "n" }, "<leader>a", vim.lsp.buf.code_action) -- Rider 风格 Code Action
key("n", "<leader>lf", vim.lsp.buf.format)
key("n", "<leader>n", "<cmd>enew<cr>", { desc = "New empty buffer" })

-- 系统剪贴板
key({ "n", "v" }, "<leader>c", '"+y', { desc = "copy to system clipboard" })
key({ "n", "v" }, "<leader>x", '"+d', { desc = "cut to system clipboard" })
key({ "n", "v" }, "<leader>p", '"+p', { desc = "paste to system clipboard" })

-- 窗口切换
key("n", "<A-w>", "<C-w>w", { desc = "focus windows" })

-- 行移动
key("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
key("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
key("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
key("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- 调整窗口大小
key("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
key("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
key("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
key("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- 文件/插件快捷键
key({ "n", "i", "v" }, "<C-s>", "<ESC>:write<CR>", { desc = "save file" })
key("n", "<leader>e", ":lua MiniFiles.open()<CR>", { desc = "open file explorer" })
key("n", "<leader>f", ":Pick files<CR>", { desc = "open file picker" })
key("n", "<leader>h", ":Pick help<CR>", { desc = "open help picker" })
key("n", "<leader>b", ":Pick buffers<CR>", { desc = "open buffer picker" })
key("n", "<leader>dd", vim.diagnostic.open_float, { desc = "diagnostic messages" })

-- LSP 快捷键
key("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
key("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
key("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
key("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
key("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
key("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP code action" })

-- 快速跳转诊断
key("n", "[d", function()
    vim.diagnostic.jump({ wrap = true, count = -1 })
end, { desc = "prev diagnostic" })
key("n", "]d", function()
    vim.diagnostic.jump({ wrap = true, count = 1 })
end, { desc = "next diagnostic" })

--------------------------------------------------------------------------------
-- 3. 插件管理 & 加载
--------------------------------------------------------------------------------
-- 基础插件：主题、Mason、LSP、补全、自动配对
vim.pack.add({
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
    "seblyng/roslyn.nvim",  -- C# 支持
    "saghen/blink.lib",     -- 补全引擎
    "saghen/blink.cmp",     -- 补全引擎
    "echasnovski/mini.pairs", -- 自动括号
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim", -- 必选依赖
    -- { "nvim-telescope/telescope-fzf-native.nvim", build = "make"},
    "nvim-telescope/telescope-fzf-native.nvim",
    "lewis6991/gitsigns.nvim", -- 必选依赖
    "https://github.com/shatur/neovim-ayu",
})


local cmp = require('blink.cmp')
cmp.build():wait(60000)
cmp.setup()

vim.cmd("colorscheme ayu-mirage")

-- 初始化 Mason
require("mason").setup({
    registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
    },
})
require("gitsigns").setup({ current_line_blame = true })

-- 配置 Blink.cmp (补全)
require("blink.cmp").setup({
    keymap = { preset = "super-tab" },
    completion = {
        list = { selection = { preselect = true, auto_insert = false } },
        menu = { border = "rounded" },
        documentation = { auto_show = true, window = { border = "rounded" } },
        ghost_text = { enabled = true },
    },
    signature = { enabled = true, window = { border = "rounded" } },
})

-- 初始化 Mini.Pairs (自动括号)
require("mini.pairs").setup()

--------------------------------------------------------------------------------
-- 4. LSP 服务初始化
--------------------------------------------------------------------------------
local lspconfig = require("lspconfig")

-- 统一处理所有 LSP 的 Inlay Hints
local on_attach = function(client, bufnr)
    if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
end

-- Mason-lspconfig 自动配置通用 Server (如 lua_ls, clangd)
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls" },
    handlers = {
        function(server_name)
            lspconfig[server_name].setup({
                on_attach = on_attach,
                capabilities = require("blink.cmp").get_lsp_capabilities(),
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        hint = { enable = true, paramName = "All" },
                    },
                },
            })
        end,
    },
})

-- 特殊配置 Roslyn (C#) - 不要放在 mason-lspconfig 的 handlers 里
require("roslyn").setup({
    config = {
        on_attach = on_attach,
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = {
            ["csharp|inlay_hints"] = {
                csharp_enable_inlay_hints_for_implicit_object_creation = true,
                csharp_enable_inlay_hints_for_implicit_variable_types = true,
                csharp_enable_inlay_hints_for_lambda_parameter_types = true,
                csharp_enable_inlay_hints_for_types = true,
            },
        },
    },
})

-- 优化 Inlay Hint 颜色 (更像 Rider 的虚色)
vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#808080", italic = true })

require("telescope").setup({
    defaults = {
        -- 常用配置
        initial_mode = "insert", -- 打开时直接进入输入模式
        theme = "dropdown", -- 使用下拉样式，更像 IDE
        file_ignore_patterns = { -- 忽略这些文件夹
            "node_modules",
            "%.bin/",
            "%.obj/",
            "%.git/",
            "target/",
            "build/",
        },
        -- 搜索设置
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden", -- 搜隐藏文件
            "--glob",
            "!**/.git/*", -- 但排除 .git 目录
        },
    },
    pickers = {
        find_files = {
            hidden = true, -- find_files 也要搜隐藏文件
        },
    },
})

local builtin = require("telescope.builtin")
-- 跳转到定义 (Go to Definition)
key("n", "gd", builtin.lsp_definitions, { desc = "Telescope: Definition" })

-- 查看引用 (Find References) - 这比原生的列表好用太多，带代码预览
key("n", "gr", builtin.lsp_references, { desc = "Telescope: References" })

-- 悬浮提示 (Hover)
-- 注意：K (Hover) 建议保留原生，因为 Telescope 没有对应的“悬浮文档”功能
-- 但你可以用 lsp_implementations 来替代部分查找逻辑
key("n", "K", vim.lsp.buf.hover, { desc = "LSP: Hover Documentation" })

-- 代码操作 (Code Action)
key({ "n" }, "<leader>a", function()
    builtin.lsp_code_actions(require("telescope.themes").get_cursor())
end, { desc = "Telescope: Code Action" })
key("n", "<leader>a", "<cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "Code Action" })

key("n", "<leader>ld", require("gitsigns").reset_hunk, { desc = "撤销当前代码块修改" })
key("n", "<leader>lp", require("gitsigns").preview_hunk, { desc = "预览代码块差异" })

key("n", "<leader>fr", builtin.oldfiles, { desc = "Telescope Old Files" })
key("n", "<leader>ff", builtin.find_files, { desc = "Telescope Find Files" })
key("n", "<leader>fg", builtin.live_grep, { desc = "Telescope Live Grep" })
key("n", "<Tab>", function()
    require("telescope.builtin").buffers({
        sort_mru = true,
        initial_mode = "normal",
        -- 核心：列表从上往下排
        sorting_strategy = "ascending",
        -- 核心：使用下拉或中心布局，隐藏预览并压缩高度
        layout_strategy = "center",
        -- layout_strategy = "horizontal",
        layout_config = {
            width = 0.5,
            height = 0.3,
            prompt_position = "top", -- 输入框放在顶部（配合 ascending 会很自然）
        },
        -- 彻底隐藏提示符（虽然输入框还在，但看起来像个标题）
        prompt_title = "Buffer Switcher",
        results_title = false,
        attach_mappings = function(prompt_bufnr, map)
            map("n", "d", require("telescope.actions").delete_buffer)
            -- 让 Tab 键在列表里直接向下移动，而不是切换输入框
            map("n", "<Tab>", require("telescope.actions").move_selection_next)
            map("n", "<S-Tab>", require("telescope.actions").move_selection_previous)
            return true
        end,
    })
end, { desc = "Rider-style Buffer Switcher" })

vim.diagnostic.config({
    virtual_text = {
        -- 核心配置：只在当前行显示虚拟文本
        format = function(diagnostic)
            if vim.api.nvim_win_get_cursor(0)[1] == diagnostic.lnum + 1 then
                return string.format("%s: %s", diagnostic.source or "LSP", diagnostic.message)
            end
            return nil
        end,
        prefix = "",
    },
})

-- 配合这个自动命令，在光标移动时强制刷新当前行的显示
vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
        vim.diagnostic.show()
    end,
})
