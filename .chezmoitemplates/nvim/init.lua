-- echo "{{ .chezmoi.os }}"
---@diagnostic disable: undefined-global

if vim.loader then
	vim.loader.enable()
end

if vim.lsp.inlay_hint then
	vim.lsp.inlay_hint.enable(true)
end

vim.opt.signcolumn = "yes"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.updatetime = 200
vim.g.mapleader = " "
vim.opt.smartcase = true

local key = vim.keymap.set
local gh = function(x)
	return "https://github.com/" .. x
end

key("i", "jj", "<esc>")
key({ "n", "i", "v" }, "<C-s>", "<ESC>:w<CR>")

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
key("n", "<leader>dd", vim.diagnostic.open_float, { desc = "diagnostic messages" })

-- LSP 快捷键
key("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
key("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
key("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
key("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
key("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP code action" })
key("n", "K", vim.lsp.buf.hover)
key("n", "<leader>n", "<cmd>enew<cr>", { desc = "New empty buffer" })
key("n", "<leader>fm", vim.lsp.buf.format)
key("n", "K", vim.lsp.buf.hover, { desc = "LSP: Hover Documentation" })

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
	gh("williamboman/mason.nvim"),
	gh("williamboman/mason-lspconfig.nvim"),
	gh("neovim/nvim-lspconfig"),
	gh("seblyng/roslyn.nvim"), -- C# 支持
	gh("saghen/blink.lib"), -- 补全引擎
	gh("saghen/blink.cmp"), -- 补全引擎
	gh("echasnovski/mini.pairs"), -- 自动括号
	gh("nvim-lua/plenary.nvim"), -- 必选依赖
	gh("lewis6991/gitsigns.nvim"), -- 必选依赖
	gh("shatur/neovim-ayu"),
	gh("kevinhwang91/nvim-bqf"),
	gh("ibhagwan/fzf-lua"),
	gh("milanglacier/minuet-ai.nvim"),
})

vim.cmd("colorscheme ayu-mirage")

local cmp = require("blink.cmp")
cmp.build():wait(60000)
cmp.setup({
	keymap = {
		preset = "none",
		["<Tab>"] = { "select_next", "fallback" },
		["<S-Tab>"] = { "select_prev", "fallback" },
		["<CR>"] = { "accept", "fallback" },
	},
	completion = {
		list = { selection = { preselect = true, auto_insert = false } },
		menu = { border = "rounded" },
		documentation = { auto_show = true, window = { border = "rounded" } },
		ghost_text = { enabled = true },
	},
	signature = { enabled = true, window = { border = "rounded" } },
	sources = {
		default = { "lsp", "path", "buffer", "snippets", "minuet" },
		providers = {
			minuet = {
				name = "minuet",
				module = "minuet.blink",
				async = true,
				timeout_ms = 3000,
				score_offset = 50, -- Gives minuet higher priority among suggestions
			},
		},
	},
})

require("minuet").setup({
	request_timeout = 2.5,
	throttle = 700, -- Increase to reduce costs and avoid rate limits
	debounce = 500, -- Increase to reduce costs and avoid rate limits
	provider = "openai_fim_compatible",
	provider_options = {
		openai_fim_compatible = {
			api_key = "DEEPSEEK_API_KEY",
			name = "deepseek",
			optional = {
				max_tokens = 256,
				top_p = 0.9,
			},
		},
	},
})

-- 初始化 Mason
require("mason").setup({
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
})
require("gitsigns").setup({ current_line_blame = true })

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
-- vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#808080", italic = true })

key("n", "<leader>ld", require("gitsigns").reset_hunk, { desc = "撤销当前代码块修改" })
key("n", "<leader>lp", require("gitsigns").preview_hunk, { desc = "预览代码块差异" })

local builtin = require("fzf-lua")
builtin.setup({
	fzf_opts = {
		-- bg+ 是选中行的背景，fg+ 是选中行的文字
		-- hl 是匹配到的关键词颜色
		["--color"] = "fg:15,bg:-1,hl:203,fg+:255,bg+:238,hl+:203,info:109,prompt:203,pointer:203,marker:203,spinner:109,header:109",
	},
})
key("n", "<leader>fr", builtin.oldfiles)
key("n", "<leader>ff", builtin.files)
key("n", "<leader>fg", builtin.live_grep)
key("n", "<Tab>", builtin.buffers)
key("n", "<leader>fl", builtin.lsp_live_workspace_symbols)

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

function ToggleQuickfix()
	for _, win in ipairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			vim.cmd("cclose")
			return
		end
	end
	vim.cmd("copen")
end

vim.keymap.set("n", "<leader>q", ToggleQuickfix)
