local M = {}

local hsl = require('lush').hsl

--- Normally we don't print debug messages
local debug = function() end

--- List of buffers, and the created
local buffers = {}

local function reset_buffer(buffer_id)
    buffers[buffer_id] = {
        next_id = 1,
        rotation = 0,
    }
end

local function setup_buffer(buffer_id)
    if buffers[buffer_id] == nil then
        reset_buffer(buffer_id)
    end
end

--- Set up initial color
local function setup_highlight_color()
    local normal_highlight = vim.api.nvim_get_hl(0, { name = 'Normal' })
    local background_color = hsl(string.format('#%06x', normal_highlight.bg))
    if vim.o.background == 'light' then
        return background_color.da(30).sa(30)
    else
        return background_color.li(20)
    end
end

local color = setup_highlight_color()

local function generate_group_name(num)
    return 'HLGroup' .. num
end

---@return string # Name used for syntax highlight group
local function generate_next_group_name(buffer_id)
    local new_name = generate_group_name(buffers[buffer_id].next_id)
    buffers[buffer_id].next_id = buffers[buffer_id].next_id + 1
    return new_name
end

---@return string # New color intended for background
local function generate_color(buffer_id)
    -- Rotate by something that *isn't* a even divisor of 360, as
    -- to be able to rotate several times before hitting same color
    local rotation = buffers[buffer_id].rotation
    buffers[buffer_id].rotation = buffers[buffer_id].rotation + 70
    return color.rotate(rotation).hex
end

function M.setup(config)
    if config and config.debug then
        -- Set debug function to become a print
        debug = function(msg) print(msg) end
    end

    vim.api.nvim_create_user_command('Highlighter',
        function(opts)
            debug('Highlight opts=' .. vim.inspect(opts))

            local buffer_id = vim.api.nvim_get_current_buf()
            setup_buffer(buffer_id)

            local searchterm = '\\<' .. vim.fn.expand('<cword>') .. '\\>'
            vim.fn.histadd("search", searchterm)
            vim.fn.search(searchterm, 'n')

            local name = generate_next_group_name(buffer_id)
            vim.cmd('syntax match ' .. name .. ' /' .. searchterm .. '/')
            vim.api.nvim_set_hl(0, name, { bg = generate_color(buffer_id), })
        end, {
            --[[ TODO: Could allow range, but this is tricky with visual
        --          selection spanning multiple lines ]] --
        })

    vim.api.nvim_create_user_command('HighlighterClear',
        function(_)
            local buffer_id = vim.api.nvim_get_current_buf()
            for i = 1, buffers[buffer_id].next_id do
                local name = generate_group_name(i)
                vim.cmd('highlight clear ' .. name)
                vim.cmd('syntax clear ' .. name)
            end
            reset_buffer(buffer_id)
        end, {
        })
end

return M

-- vim: set et ts=4 sw=4 ss=4 tw=100:
