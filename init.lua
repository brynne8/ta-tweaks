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
  local word = 'TODO'
  buffer.search_flags = buffer.FIND_WHOLEWORD + buffer.FIND_MATCHCASE
  buffer:target_whole_document()
  while buffer:search_in_target(word) > -1 do
    buffer:indicator_fill_range(buffer.target_start,
                                buffer.target_end - buffer.target_start)
    buffer:set_target_range(buffer.target_end, buffer.length)
  end
end)