local api = vim.api
local win, buf
local boltbuf, boltline, boltwin, boltbucket

local bufkeymap = api.nvim_buf_set_keymap

-- helper: trum space in string
local function trimspace(str)
	if not str then
		return ""
	end
	return str:gsub("^%s*(.-)%s*$", "%1")
end

-- helper, find bucket name above
local function find_bucket_above()
	-- record origin cursor
	local row, col = unpack(api.nvim_win_get_cursor(0))
	for line = row, 0, -10 do
		local endline = line - 10
		if endline < 0 then
			endline = 0
		end
		local lines = api.nvim_buf_get_lines(0, endline, line, false)
		for i = #lines, 1, -1 do
			if #lines[i] > 0 then
				-- has chars
				local firstchar = lines[i]:sub(1,1)
				if firstchar ~= "\t" and firstchar ~= " " then
					api.nvim_win_set_cursor(0, { row, col })
					return { lines[i], line - (#lines - i) }
				end
			end
		end
	end
	api.nvim_win_set_cursor(0, { row, col })
	return nil
end

--[[
-- open_float -- opens the folat window and set teh keymap
--
-- keymap in the form of
-- {
--      {
--      key = "k"
--      map = "v"
--      is_lua = true|false
--      },
-- }
--
-- cursorend, should move cursor to the end of the line
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

-- helper: find match for key => value
-- if needspace is true, then the first space need to be present
local function getmatch(txt, needspace)
	local space = "*"
	if needspace then
		print("need space")
		space = "+"
	end
	local start, end_, key, value = string.find(txt, "^%s"..space.."([^(=>)]-)%s*=>%s*(.-)%s*$")
	if not start then
		return {}
	end

	return {key, value}
end

--[[
-- callback from a float window, replace .boltdb buffer's line with the content in the float window
--]]
local function replace_entry()
	local txt = api.nvim_buf_get_lines(0, 0, 1, false)
	local matchinfo = getmatch(txt[1])

	local linecontent = api.nvim_buf_get_lines(boltbuf, boltline - 1, boltline, false)
	local matchinfo2 = getmatch(linecontent[1])

	close_window()
	if #matchinfo ~= 0 then
		if matchinfo2[1] ~= matchinfo[1] then
			-- key is not the same
			api.nvim_err_writeln("modified key mismatch")
			return nil
		end
		vim.fn["BoltviewerCreateEntryAnyway"](boltbucket, matchinfo[1], matchinfo[2])
		api.nvim_buf_set_lines(
			boltbuf,
			boltline - 1,
			boltline,
			false,
			{ "\t" .. matchinfo[1] .. " => " .. matchinfo[2] }
		)
	else
		api.nvim_err_writeln("entry format key => val error")
	end
end

--[[
-- callback from a float window, insert a entry in .boltdb content
--]]
local function insert_entry()
	local txt = api.nvim_buf_get_lines(0, 0, 1, false)
	local matchinfo = getmatch(txt[1])
	close_window()
	if #matchinfo ~= 0 then
		vim.fn["BoltviewerCreateEntry"](boltbucket, matchinfo[1], matchinfo[2])
		api.nvim_buf_set_lines(boltbuf, boltline, boltline, false, { "\t" .. matchinfo[1] .. " => " .. matchinfo[2] })
	else
		api.nvim_err_writeln("entry format key => val error")
	end
end

--[[
-- callback from the float window, insert a bucket to a .boltdb file
--]]
local function insert_bucket()
	local txt = api.nvim_buf_get_lines(0, 0, 1, false)
	local bktrawname = txt[1]
	local bktname = trimspace(bktrawname)

	close_window()
	vim.fn["BoltviewerCreateBucket"](bktname)
	local info = find_bucket_above()
	local bucketline
	if not info then
		print("bucket not found")
		bucketline = 1
	else
		_, bucketline = unpack(info)
		print("bucket line " .. bucketline)
	end
	api.nvim_buf_set_lines(boltbuf, bucketline - 1, bucketline - 1, false, { bktname })
	--print("local txt is ", txt[1])
end

--[[
-- callback from float window, delete an entry
--]]
local function delete_entry(entryname)
	close_window()
	vim.fn["BoltviewerDeleteEntry"](boltbucket, entryname)
	-- print("boltline = " .. boltline)
	api.nvim_buf_set_lines(boltbuf, boltline - 1, boltline, false, {})
end

--[[
-- callback from a float window, delete a bucket
--]]
local function delete_bucket()
	close_window()
	vim.fn["BoltviewerDeleteBucket"](boltbucket)
	api.nvim_buf_set_lines(boltbuf, boltline - 1, boltline, false, {})
end

--[[
-- api: delete the entry or bucket under the cursor in .boltdb file
--]]
local function Delete()
	local cursor = api.nvim_win_get_cursor(0)
	local r, _ = unpack(cursor)

	boltline = r

	local text = api.nvim_buf_get_lines(0, r - 1, r, false)
	if #text ~= 1 then
		print("text line error")
	end

	-- index starts at 1
	local txt = text[1]
	local matchinfo = getmatch(txt, true)


	if #matchinfo ~= 0 then
		print("get match '" .. matchinfo[1].. "'")
		-- is entry
		local info = find_bucket_above()
		if not info then
			api.nvim_err_writeln("bucket not found")
			return nil
		end
		local bktname, _ = unpack(info)
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
		open_float({ "delete entry " .. matchinfo[1] .. "? [y/n] " }, 'entry in "' .. bktname .. '"', keymap, true)
	else
		local map_ok = "delete_bucket()"
		local bucketname = trimspace(txt)
		boltbucket = bucketname
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
		open_float({ "delete bucket " .. bucketname .. "? [y/n] " }, "delete bucket", keymap, true)
	end
end

-- helper, get current buff's line under the content
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

-- api, Insert a bucket, using the current line as a startup
local function LuaInsertBucket()
	local txt = get_cursor_line()
	if not txt then
		return nil
	end

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
	open_float({ txt }, 'insert bucket', keymap)
end

-- helper, insert or modify an entry, use the current line under cursor as a startup
-- action is the prompt in popup window
local function luaInsertEntry(insertfunction, action)
	local txt = get_cursor_line()
	if not txt then
		return nil
	end

	local info = find_bucket_above()
	if not info then
		api.nvim_err_writeln("no bucket name found")
		return nil
	end
	local bktname, _ = unpack(info)
	bktname = trimspace(bktname)
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
	open_float({ txt }, action .. ' entry', keymap)
end

-- api, insert entry with the content under cursor as a atartup
local function LuaInsertEntry()
	luaInsertEntry("insert_entry()", "insert")
end

-- api, modify entry with the content under cursor as a atartup
local function modify_entry()
	luaInsertEntry("replace_entry()", "modify")
end

-- export these local variables
return {
	close_win = close_window,
	-- copy the line, and insert
	lua_insert_entry = LuaInsertEntry,
	lua_insert_bucket = LuaInsertBucket,
	lua_modify_entry = modify_entry,
	delete = Delete,

	insert_entry = insert_entry,
	insert_bucket = insert_bucket,
	replace_entry = replace_entry,

	delete_entry = delete_entry,
	delete_bucket = delete_bucket,
}
