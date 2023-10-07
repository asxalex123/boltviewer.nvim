local api = vim.api
local win

local function open_window()
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, true, {"hello", "world"})

    local opts = {
        relative="cursor",
        width=10,
        height=2,
        col=0,
        row=1,
    }
    win = api.nvim_open_win(buf, true, opts)
end

return {
    open_window = open_window,
}
