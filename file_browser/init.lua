-- Copyright 2007-2017 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Text-based file browser for the textadept module.
-- Pressing the spacebar activates the item on the current line.
-- Other keys are: 'p' and 'n' to navigate up or down by item, 'P' and 'N' to
-- navigate up or down by level, and 'f' and 'b' to navigate within a directory
-- by its first and last files.
module('_M.file_browser')]]

---
-- Map of directory paths to filters used by the file browser.
-- @class table
-- @name dir_filters
M.dir_filters = {}

M.styles = setmetatable({
  directory = 6, -- keyword style
  link = 5, -- number style
  socket = 8, -- operator style
}, {__index = function() return 0 end})

local function highlight_folder(start_line)
  if not (buffer._type or ''):match('^%[File Browser') then return end
  for i = start_line and start_line or 1, buffer.line_count do
    local line = buffer:get_line(i)
    if line:find('[/\\][\r\n]*$') then
      buffer:start_styling(buffer:position_from_line(i), 0xFF)
      buffer:set_styling(#line, M.styles.directory)
    end
  end
end

-- Prints a styled list of the contents of directory path *dir*.
local function print_listing(dir)
  buffer.read_only = false
  -- Retrieve listing for dir.
  local listing = {}
  for path in lfs.walk(dir, buffer._filter, 0, true) do
    listing[#listing + 1] = path
  end
  table.sort(listing)
  -- Print listing for dir, styling directories, symlinks, etc.
  local line_num = buffer:line_from_position(buffer.current_pos)
  local indent = buffer.line_indentation[line_num] + buffer.tab_width
  for i = 1, #listing do
    buffer:insert_text(buffer.line_end_position[line_num + i - 1], '\n')
    buffer.line_indentation[line_num + i] = indent
    local pos = buffer.line_indent_position[line_num + i]
    local name = listing[i]:match('[^/\\]*[/\\]?$')
    buffer:insert_text(pos, name)
  end
  buffer.read_only = true
  buffer:set_save_point()
  highlight_folder(line_num)
end

---
-- Displays a textual file browser for a directory.
-- Files shown in the browser do not match any pattern in either string or table
-- *filter* (`lfs.default_filter` if *filter* is `nil`). A filter table contains
-- lUa patterns that match filenames to exclude, an optional `folders` sub-table
-- that contains patterns matching directories to exclude, and an optional
-- `extensions` sub-table that contains raw file extensions to exclude. Any
-- patterns starting with '!' exclude files and directories that do not match
-- the pattern that follows.
-- @param dir Directory to show initially. The user is prompted for one if none
--   is given.
-- @param filter Optional filter for files and directories to exclude. The
--   default value comes from `M.dir_filters`.
-- @name init
function M.init(dir, filter)
  dir = dir or ui.dialogs.fileselect{
    title = 'Open Directory', select_only_directories = true
  }
  if not dir then return end
  M.root_dir = dir
  if not filter then filter = M.dir_filters[dir] end
  if #_VIEWS == 1 then ui.goto_view(view:split(true)) end
  local buffer = buffer.new()
  buffer._type = '[File Browser - '..dir..(not WIN32 and '/' or '\\') .. ']'
  buffer._filter = filter
  buffer:insert_text(-1, dir..(not WIN32 and '/' or '\\'))
  print_listing(dir)
end

local function raw_init(dir)
  M.root_dir = dir
  buffer._filter = M.dir_filters[dir]
  buffer:insert_text(-1, dir)
  print_listing(dir)
end

-- Returns the full path of the file on line number *line_num*.
-- @param line_num The line number of the file to get the full path of.
local function get_path(line_num)
  -- Determine parent directories of the tail all the way up to the root.
  -- Subdirectories are indented.
  local parts = {}
  local indent = buffer.line_indentation[line_num]
  local level = indent
  for i = line_num, 0, -1 do
    local j = buffer.line_indentation[i]
    if j < level then
      table.insert(parts, 1, buffer:get_line(i):match('^%s*([^\r\n]+)'))
      level = j
    end
    if j == 0 then break end
  end
  parts[#parts + 1] = buffer:get_line(line_num):match('^%s*([^\r\n]+)')
  return table.concat(parts)
end

-- Expand/contract directory or open file.
events.connect('char_added', function(code)
  if not (buffer._type or ''):match('^%[File Browser.-%]') or
     not buffer.read_only then
    return
  end
  local buffer = buffer
  local line_num = buffer:line_from_position(buffer.current_pos)
  local indent = buffer.line_indentation[line_num]
  if code == 32 then
    -- Open/Close the directory or open the file.
    local path = get_path(line_num)
    if path:sub(-1, -1) == (not WIN32 and '/' or '\\') then
      if buffer.line_indentation[line_num + 1] <= indent then
        print_listing(path)
      else
        -- Collapse directory contents.
        local first_visible_line = buffer.first_visible_line
        local s, e = buffer:position_from_line(line_num + 1), nil
        level = indent
        for i = line_num + 1, buffer.line_count do
          if buffer:get_line(i):match('^[^\r\n]') and
             buffer.line_indentation[i] <= indent then break end
          e = buffer:position_from_line(i + 1)
        end
        buffer.read_only = false
        buffer:set_sel(s, e)
        buffer:replace_sel('')
        buffer.read_only = true
        buffer:set_save_point()
        buffer:line_up()
        buffer:line_scroll(0, first_visible_line - buffer.first_visible_line)
        highlight_folder(line_num)
      end
    else
      -- Open file in a new split or other existing split.
      if #_VIEWS == 1 then
        _, new_view = view:split(true)
        ui.goto_view(new_view)
      else
        for i, other_view in ipairs(_VIEWS) do
          if view ~= other_view then ui.goto_view(other_view) break end
        end
      end
      io.open_file(path)
    end
  elseif code == string.byte('n') then
    buffer:line_down()
  elseif code == string.byte('p') then
    buffer:line_up()
  elseif code == string.byte('N') then
    for i = line_num + 1, buffer.line_count do
      buffer:line_down()
      if buffer.line_indentation[i] <= indent then break end
    end
  elseif code == string.byte('P') then
    for i = line_num - 1, 0, -1 do
      buffer:line_up()
      if buffer.line_indentation[i] <= indent then break end
    end
  elseif code == string.byte('f') then
    for i = line_num + 1, buffer.line_count do
      if buffer.line_indentation[i] < indent then break end
      buffer:line_down()
    end
  elseif code == string.byte('b') then
    for i = line_num - 1, 0, -1 do
      if buffer.line_indentation[i] < indent then break end
      buffer:line_up()
    end
  elseif code == string.byte('d') then
    local path = get_path(line_num)
    local btn = ui.dialogs.ok_msgbox({
      title = 'Remove',
      text = 'Delete this file / folder?'
    })
    ui.statusbar_text = path
    if btn == 1 then
      if path:sub(-1, -1) == (not WIN32 and '/' or '\\') then
        if WIN32 then os.execute('rd /s/q "'..path..'"')
        else os.execute('rm -rf "'..path..'"') end
      else
        os.remove(path)
      end
      buffer.read_only = false
      buffer:line_delete()
      while line_num <= buffer.line_count do
        if buffer.line_indentation[line_num] <= indent then break end
        buffer:line_delete()
      end
      buffer.read_only = true
      buffer:set_save_point()
    end
  end
end)

-- Initialize when restoring a File Browser session
events.connect(events.FILE_OPENED, function (filename)
  if filename then
    local filepath = filename:match('^%[File Browser %- (.+)%]$')
    if filepath then raw_init(filepath) end
  end
end)

events.connect(events.BUFFER_AFTER_SWITCH, highlight_folder)
events.connect(events.VIEW_AFTER_SWITCH, highlight_folder)

keys['ctrl+p'] = function ()
  if not M.root_dir then return end
  local file_list = {}
  local path_list = {}
  for filename in lfs.walk(M.root_dir, buffer._filter, 9) do
    table.insert(file_list, filename)
    table.insert(path_list, filename:sub(#M.root_dir + 2))
  end 
  local button, i = ui.dialogs.filteredlist{
    title = _L['Open'], columns = _L['File'], items = path_list,
    width = CURSES and ui.size[1] - 2 or nil
  }
  if button == 1 and i then io.open_file(file_list[i]) end
end

return M
