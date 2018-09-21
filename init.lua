buffer:set_theme('light', {font = 'WenQuanYi Micro Hei Mono'})

_M.file_browser = require('file_browser')

require('folding')
require('css')
require('html')
require('js')

--- highlight all todos after lexer loaded
local INDIC_TODO = _SCINTILLA.next_indic_number()

buffer.indic_style[INDIC_TODO] = buffer.INDIC_ROUNDBOX
if not CURSES then buffer.indic_under[INDIC_TODO] = true end

buffer.indic_fore[INDIC_TODO] = 0x00FEFE
buffer.indic_alpha[INDIC_TODO] = 255

events.connect(events.LEXER_LOADED, function(lexer)
  buffer.indicator_current = INDIC_TODO
  local word1 = 'TODO'
  local word2 = 'FIXME'
  buffer.search_flags = buffer.FIND_WHOLEWORD + buffer.FIND_MATCHCASE
  buffer:target_whole_document()
  while buffer:search_in_target(word1) > -1 do
    buffer:indicator_fill_range(buffer.target_start,
                                buffer.target_end - buffer.target_start)
    buffer:set_target_range(buffer.target_end, buffer.length)
  end
  buffer:target_whole_document()
  while buffer:search_in_target(word2) > -1 do
    buffer:indicator_fill_range(buffer.target_start,
                                buffer.target_end - buffer.target_start)
    buffer:set_target_range(buffer.target_end, buffer.length)
  end
end)

events.connect(events.CHAR_ADDED, function(ch)
  if ch ~= string.byte(':') then return end
  -- Perform highlighting of TODO or FIXME just added.
  buffer.indicator_current = INDIC_TODO
  if buffer:get_cur_line():match('TODO:%s-$') then
    buffer:indicator_fill_range(buffer.current_pos - 5, 4)
  elseif buffer:get_cur_line():match('FIXME:%s-$') then
    buffer:indicator_fill_range(buffer.current_pos - 6, 5)
  end
end)

events.connect(events.LEXER_LOADED, function(lexer)
  for i = 0, buffer.line_count - 1 do
    if buffer.fold_expanded[i] and buffer.line_visible[i] then
      local last_line_num = buffer:get_last_child(i, -1)
      if last_line_num - i >= 100 then
        buffer:toggle_fold(i)
      end
      i = last_line_num
    end
  end
end)