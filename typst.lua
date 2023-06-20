-- Copyright 2023 Alexander Misel. See LICENSE.
-- Typst LPeg lexer.

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(..., {no_user_word_lists = true})

-- Block elements.
local function h(n)
  return lex:tag(string.format('%s.h%s', lexer.HEADING, n),
    lexer.to_eol(lexer.starts_line(string.rep('=', n))))
end
lex:add_rule('header', h(6) + h(5) + h(4) + h(3) + h(2) + h(1))

lex:add_rule('hr',
  lex:tag('hr', lpeg.Cmt(lexer.starts_line(lpeg.C(S('*-_')), true), function(input, index, c)
    local line = input:match('[^\r\n]*', index):gsub('[ \t]', '')
    if line:find('[^' .. c .. ']') or #line < 2 then return nil end
    return (select(2, input:find('\r?\n', index)) or #input) + 1 -- include \n for eolfilled styles
  end)))

lex:add_rule('list', lex:tag(lexer.LIST,
  lexer.starts_line(lexer.digit^1 * '.' + S('*+-'), true) * S(' \t')))

local hspace = lexer.space - '\n'
local blank_line = '\n' * hspace^0 * ('\n' + P(-1))

local code_block = lexer.range(lexer.starts_line('```', true), '\n```' * hspace^0 * ('\n' + P(-1)))
local code_inline = lpeg.Cmt(lpeg.C(P('`')^1), function(input, index, bt)
  -- `foo`, ``foo``, ``foo`bar``, `foo``bar` are all allowed.
  local _, e = input:find('[^`]' .. bt .. '%f[^`]', index)
  return (e or #input) + 1
end)
lex:add_rule('block_code', lex:tag(lexer.CODE, code_block + code_inline))

lex:add_rule('blockquote',
  lex:tag(lexer.STRING, lpeg.Cmt(lexer.starts_line('>', true), function(input, index)
    local _, e = input:find('\n[ \t]*\r?\n', index) -- the next blank line (possibly with indentation)
    return (e or #input) + 1
  end)))

lex:add_rule('math', lex:tag(lexer.REGEX, lexer.range('$')))
-- Span elements.
lex:add_rule('escape', lex:tag(lexer.DEFAULT, P('\\') * 1))

local function word_match(list)
  local rule = nil
  for _, v in ipairs(list) do
    if not rule then
      rule = P(v)
    else
      rule = rule + v
    end
  end
  return rule
end

local keyword = lex:tag(lexer.KEYWORD, word_match({
  'none', 'auto', 'true', 'false', 'not', 'and', 'or',
  'let', 'set', 'show', 'wrap', 'if', 'else', 'for', 'in',
  'as', 'while', 'break', 'continue', 'return', 'import',
  'include', 'from'
})) * -lexer.alpha
local operator = lex:tag(lexer.OPERATOR, word_match({
  '\\', '/', '[', ']', '{', '}', '#', '~', '-', '.', ':',
  '*', '_', '`', '$', '=', '<', '>', '@'
}))
local func_call = lex:tag(lexer.FUNCTION, (lexer.alpha + '_') * (lexer.alnum + S'_-')^0) * #S'(['

local str = lex:tag(lexer.STRING, lexer.range("'") + lexer.range('"'))

local hash_body = (-lexer.newline * (operator + keyword + func_call + str + lex:tag(lexer.DEFAULT, 1)))^1

lex:add_rule('hash_expr', lex:tag(lexer.PREPROCESSOR, lexer.starts_line('#', true)) *
                hash_body)

return lex
