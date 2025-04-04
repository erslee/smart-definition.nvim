local M = {}

local function get_definition()
	local params = vim.lsp.util.make_position_params()
	local result = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 1000)
	if not result then
		return nil
	end

	for _, res in pairs(result) do
		if res.result and #res.result > 0 then
			return res.result[1]
		end
	end

	return nil
end

local function get_definition_location()
	local location = get_definition()
	if not location then
		return nil
	end

	local uri = location.uri or location.targetUri
	local range = location.range or location.targetRange

	if not uri or not range then
		return nil
	end

	return {
		uri = uri,
		range = range,
	}
end

M.goto_definition_smart = function()
	local target = get_definition_location()
	if target == nil then
		vim.notify("No definition found")
		return
	end
	local filepath = vim.uri_to_fname(target.uri)
	local line = target.range.start.line
	local col = target.range.start.character

	filepath = vim.fn.fnamemodify(filepath, ":p")

	local buf_exists = nil
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p") == filepath then
			buf_exists = buf
			break
		end
	end

	if buf_exists then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == buf_exists then
				vim.api.nvim_set_current_win(win) -- Switch to that window
				vim.api.nvim_win_set_cursor(win, { line + 1, col }) -- Move cursor
				return
			end
		end

		vim.api.nvim_set_current_buf(buf_exists)
		vim.api.nvim_win_set_cursor(0, { line + 1, col })
	else
		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
	end
end

M.setup = function()
	vim.keymap.set("n", "gd", M.goto_definition_smart, { desc = "Go to definition" })
end

return M
