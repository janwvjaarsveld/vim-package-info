--------------------------------------------------------------------------------
-- vim-readme.lua
--------------------------------------------------------------------------------
local M = {}

-- Default configuration
local default_config = {
	-- Floating window configuration
	window = {
		width_ratio = 0.8, -- The fraction of the editor's width
		height_ratio = 0.8, -- The fraction of the editor's height
		border = "rounded", -- Available options: 'none', 'single', 'double', 'rounded', etc.
	},
	-- Default branches to try if README is not on main
	fallback_branches = { "main", "master" },
	-- User command name
	command_name = "VimReadme",
	-- Keymap: pass map = false to skip setting a keymap
	key_bindings = {
		get_package_info = "<leader>vr",
		close = "q", -- Optional: Change close key to 'x'
		open_git = "o",
	},
}

-- This holds the merged user config + defaults
local config = {}

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

--- Create a floating window with config-based width and height.
--- @param opts table: { buf = <buf_handle>, title = <string> }
local function create_floating_window(opts)
	opts = opts or { title = "Vim Readme" }
	local width = math.floor(vim.o.columns * config.window.width_ratio)
	local height = math.floor(vim.o.lines * config.window.height_ratio)

	-- Calculate position for centering
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Create or reuse the given buffer
	local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer

	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = config.window.border,
		title = opts.title,
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)
	return { buf = buf, win = win }
end

--- Get the text between quotes where the cursor currently is.
local function get_text_between_quotes()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_num, col_num = cursor[1], cursor[2] + 1
	local line = vim.api.nvim_get_current_line()

	local quotes = { '"', "'" }
	for _, quote in ipairs(quotes) do
		-- Find the position of the last quote before the cursor
		local start_pos = line:sub(1, col_num):reverse():find(quote)
		if start_pos then
			start_pos = col_num - start_pos + 1
			local end_pos = line:sub(col_num):find(quote)
			if end_pos then
				return line:sub(start_pos + 1, col_num - 1 + end_pos - 1)
			end
		end
	end
	return nil
end

--- Retrieve the README from a GitHub repository, trying multiple branches if needed.
local function retrieve_package_readme(url)
	local function parse_raw_url(raw_url)
		-- e.g. https://raw.githubusercontent.com/user/repo/branch/path/to/file.md
		local pattern = "^https://raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/(.+)$"
		local owner, repo, branch, path = raw_url:match(pattern)
		return owner, repo, branch, path
	end

	local function construct_raw_url(owner, repo, branch, path)
		return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", owner, repo, branch, path)
	end

	local function url_exists(raw_url)
		local headers = vim.fn.system({ "curl", "-Is", raw_url })
		local status_code = headers:match("HTTP/%d+ (%d%d%d)") or "0"
		return tonumber(status_code) == 200
	end

	local owner, repo, branch, path = parse_raw_url(url)
	if not owner then
		print("Invalid GitHub raw URL format. Please provide a valid raw URL.")
		return
	end

	-- Try the stated branch first, then fallback branches from config.
	local branches_to_try = vim.tbl_flatten({ branch, config.fallback_branches })

	local successful = false
	local final_url = ""

	for _, b in ipairs(branches_to_try) do
		local test_url = construct_raw_url(owner, repo, b, path)
		if url_exists(test_url) then
			final_url = test_url
			successful = true
			break
		end
	end

	if not successful then
		print("Failed to fetch the Markdown file. Please check the URL and branch names.")
		return
	end

	local result = vim.fn.system({ "curl", "-s", final_url })
	if vim.v.shell_error ~= 0 then
		print("Error fetching the Markdown file. Please check the URL.")
		return
	end

	return result
end

--- Fetch a GitHub README (Markdown) in a floating window.
local function fetch_markdown(package_name)
	if not package_name or package_name == "" then
		print("Usage: :" .. config.command_name .. " <username/repository>")
		return
	end

	local git_link = "https://github.com/" .. package_name
	local git_url = "https://raw.githubusercontent.com/" .. package_name .. "/main/README.md"

	local result = retrieve_package_readme(git_url)
	if not result then
		-- retrieve_package_readme will print an error if needed
		return
	end

	-- Create/reuse floating window
	local floating = create_floating_window({
		title = package_name,
	})

	-- Buffer/window settings
	vim.bo[floating.buf].filetype = "markdown"
	vim.bo[floating.buf].bufhidden = "delete"
	vim.bo[floating.buf].buftype = ""
	vim.wo[floating.win].wrap = true
	vim.api.nvim_buf_set_name(floating.buf, package_name .. "README.md")

	-- Clear existing content and insert the fetched lines
	local lines = vim.split(result, "\n")
	vim.api.nvim_buf_set_lines(floating.buf, 0, -1, false, lines)

	-- Keymaps in floating buffer
	vim.api.nvim_buf_set_keymap(
		floating.buf,
		"n",
		config.key_bindings.close,
		"<cmd>bd!<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		floating.buf,
		"n",
		config.key_bindings.open_git,
		string.format([[<cmd>lua vim.ui.open("%s")<CR>]], git_link),
		{ noremap = true, silent = true }
	)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Setup function to initialize user config and commands.
--- @param user_config? table: The user configuration
function M.setup(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- Create a user command with the configured name
	vim.api.nvim_create_user_command(config.command_name, function(opts)
		if opts.args and opts.args ~= "" then
			fetch_markdown(opts.args)
			return
		end
		-- If no args given, we try to fetch from quotes under cursor
		fetch_markdown(get_text_between_quotes())
	end, {
		nargs = "?",
		complete = "file",
		desc = string.format(
			"Fetch and display the README.md from GitHub in a floating window. Usage: :%s <user/repo>",
			config.command_name
		),
	})

	vim.keymap.set(
		"n",
		config.key_bindings.get_package_info,
		string.format("<cmd>%s<CR>", config.command_name),
		{ silent = true, noremap = true }
	)
end

return M
