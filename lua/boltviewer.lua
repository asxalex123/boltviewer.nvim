local api = vim.api
local win, buf
local boltbuf, boltline, boltwin, boltbucket

local bufkeymap = api.nvim_buf_set_keymap

--[[
-- keymap in the form of
-- {
--      {
--      key = "k"
--      map = "v"
--      is_lua = true|false
--      },
-- }
--]]
local function open_float(text, title, kmap, cursorend)
	local width = api.nvim_win_get_width(0)
	boltbuf = api.nvim_get_current_buf()
	boltwin = api.nvim_get_current_win()
	local row, _ = unpack(api.nvim_win_get_cursor(boltwin))
	boltline = row

	-- local width = api.nvim_get_option_value("columns", {scope='global'})
	-- local width = api.nvim_buf_get_var(father_buf, "columns")
	buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_var(buf, "number", false)
	-- api.nvim_buf_set_lines(buf, 0, -1, true, {"hello this is a long text"})

	local opts = {
		relative = "cursor",
		width = width,
		height = 1,
		col = 0,
		row = 1,
		border = "single",
	}
	if title ~= nil then
		opts.title = title
	end

	win = api.nvim_open_win(buf, true, opts)
	api.nvim_set_option_value("number", false, { win = win })
	if text ~= nil then
		api.nvim_buf_set_lines(buf, 0, -1, true, text)
		if cursorend then
			api.nvim_win_set_cursor(win, { 1, #text[1] })
		end
	end
	if kmap ~= nil then
		local options = {
			noremap = true,
			silent = true,
		}
		for _, v in ipairs(kmap) do
			if v.is_lua then
				bufkeymap(buf, "n", v.key, ":lua require'boltviewer'." .. v.map .. "<cr>", options)
			else
				bufkeymap(buf, "n", v.key, v.map .. "<cr>", options)
			end
		end
	end
end

local function close_window()
	api.nvim_win_close(win, true)
end

local function getmatch(txt)
	local match = string.gmatch(txt, "[ \t]+([^ \t]+)[ \t]*=>[ \t]*(.*)")
	local matchinfo = {}
	for k, v in match do
		table.insert(matchinfo, k)
		table.insert(matchinfo, v)
	end
	return matchinfo
end

local function replace_entry()
	local txt = api.nvim_buf_get_lines(0, 0, 1, false)
	local matchinfo = getmatch(txt[1])
	close_window()
	if #matchinfo ~= 0 then
		vim.fn["BoltviewerCreateEntryAnyway"](boltbucket, matchinfo[1], matchinfo[2])
		api.nvim_buf_set_lines(boltbuf, boltline - 1, boltline, false, txt)
	else
		api.nvim_err_writeln("entry format key => val error")
	end
end

local function insert_entry()
	local txt = api.nvim_buf_get_lines(0, 0, 1, false)
	local matchinfo = getmatch(txt[1])
	close_window()
	if #matchinfo ~= 0 then
		vim.fn["BoltviewerCreateEntry"](boltbucket, matchinfo[1], matchinfo[2])
		api.nvim_buf_set_lines(boltbuf, boltline, boltline, false, txt)
	else
		api.nvim_err_writeln("entry format key => val error")
	end
end

local function insert_bucket()
	local txt = api.nvim_buf_get_lines(0, 0, 1, false)
	local bktname = txt[1]
	close_window()
	vim.fn["BoltviewerCreateBucket"](bktname)
	local bucketline = vim.fn["GetBucketLine"]()
	api.nvim_buf_set_lines(boltbuf, bucketline - 1, bucketline - 1, false, txt)
	print("local txt is ", txt[1])
end

local function delete_entry(entryname)
	close_window()
	vim.fn["BoltviewerDeleteEntry"](boltbucket, entryname)
	print("boltline = " .. boltline)
	api.nvim_buf_set_lines(boltbuf, boltline-1, boltline, false, {})
end

local function delete_bucket()
	close_window()
	vim.fn["BoltviewerDeleteBucket"](boltbucket)
	api.nvim_buf_set_lines(boltbuf, boltline - 1, boltline, false, {})
end

local function delete()
	local cursor = api.nvim_win_get_cursor(0)
	local r, _ = unpack(cursor)

	boltline = r

	local text = api.nvim_buf_get_lines(0, r - 1, r, false)
	if #text ~= 1 then
		print("text line error")
	end

	-- index starts at 1
	local txt = text[1]
	local matchinfo = getmatch(txt)

	if #matchinfo ~= 0 then
		-- is entry
		local bktname = vim.fn["GetBucketName"]()
		boltbucket = bktname

		local map_ok = 'delete_entry("' .. matchinfo[1] .. '")'
		local map_deny = ":q"
		local keymap = {
			{
				key = "<cr>",
				map = map_ok,
				is_lua = true,
			},
			{
				key = "y",
				map = map_ok,
				is_lua = true,
			},
			{
				key = "Y",
				map = map_ok,
				is_lua = true,
			},
			{
				key = "n",
				map = map_deny,
				is_lua = false,
			},
			{
				key = "N",
				map = map_deny,
				is_lua = false,
			},
			{
				key = "<esc>",
				map = map_deny,
				is_lua = false,
			},
		}
		open_float({"delete entry " .. matchinfo[1] .. "? [y/n] " }, ' entry in "' .. bktname .. '"', keymap, true)
	else
		local map_ok = "delete_bucket()"
		boltbucket = txt
		local keymap = {
			{
				key = "<cr>",
				map = map_ok,
				is_lua = true,
			},
			{
				key = "y",
				map = map_ok,
				is_lua = true,
			},
			{
				key = "Y",
				map = map_ok,
				is_lua = true,
			},
			{
				key = "n",
				map = ":q",
				is_lua = false,
			},
			{
				key = "N",
				map = ":q",
				is_lua = false,
			},
			{
				key = "<esc>",
				map = ":q",
				is_lua = false,
			},
		}
		open_float({ "delete bucket " .. txt .. "? [y/n] " }, "delete bucket", keymap, true)
	end
end

local function get_cursor_line()
	local cursor = api.nvim_win_get_cursor(0)
	local r, _ = unpack(cursor)

	local text = api.nvim_buf_get_lines(0, r - 1, r, false)
	if #text ~= 1 then
		print("text line error")
		return nil
	end
	return text[1]
end

local function LuaInsertBucket()
	local txt = get_cursor_line()
	if not txt then
		return nil
	end


	-- local bktname = vim.fn["GetBucketName"]()
	-- boltbucket = bktname
	local keymap = {
		{
			key = "<cr>",
			map = "insert_bucket()",
			is_lua = true,
		},
		{
			key = "<esc>",
			map = ":q",
			is_lua = false,
		},
	}
	open_float({ txt }, 'insert bucket "' .. txt .. '"', keymap)
end

-- insert function 
local function luaInsertEntry(insertfunction)
	local txt = get_cursor_line()
	if not txt then
		return nil
	end

	local bktname = vim.fn["GetBucketName"]()
	if bktname == "" then
		api.nvim_err_writeln("no bucket name found")
		return nil
	end

	boltbucket = bktname
	local keymap = {
		{
			key = "<cr>",
			map = insertfunction,
			is_lua = true,
		},
		{
			key = "<esc>",
			map = ":q",
			is_lua = false,
		},
	}
	open_float({ txt }, 'insert entry in "' .. bktname .. '"', keymap)
end

local function LuaInsertEntry()
	luaInsertEntry("insert_entry()")
end

local function modify_entry()
	luaInsertEntry("replace_entry()")
end

return {
	close_win = close_window,
	-- copy the line, and insert
	lua_insert_entry = LuaInsertEntry,
	lua_insert_bucket = LuaInsertBucket,
	lua_modify_entry = modify_entry,
	delete = delete,

	insert_entry = insert_entry,
	insert_bucket = insert_bucket,
	replace_entry = replace_entry,

	delete_entry = delete_entry,
	delete_bucket = delete_bucket,
}
