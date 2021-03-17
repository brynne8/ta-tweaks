-- Logfile LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new('log')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Errors.
lex:add_rule('error', -B(lexer.alpha) * token(lexer.ERROR, word_match([[
  EMERGENCY EMERG ALERT CRITICAL CRIT FATAL ERROR ERR FAILURE SEVERE
]], true)))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  WARNING WARN NOTICE INFO DEBUG FINE TRACE FINER FINEST info notice
]] + B('[') * lexer.word * #P(']')))

-- Date and time

local month = word_match[[
  Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
]]
local date_sep = S([[-\/]])
local digit_2 = lexer.digit * lexer.digit
local digit_2to4 = lexer.digit * lexer.digit * lexer.digit^-2
local date1 =  digit_2to4 * date_sep * (digit_2 + month) *
  date_sep * digit_2to4 * P('T')^-1
local date2 = lexer.starts_line('20') * digit_2 * digit_2 * digit_2
local time = lexer.digit * lexer.digit^-1 * ':' * digit_2 * ':' * digit_2 *
  (P('.') * digit_2 * lexer.digit^-4)^-1 * (lexer.space^-1 * S('+-') * digit_2to4 + 'Z')^-1
lex:add_rule('datetime', token(lexer.REGEX, date1 + date2 + time))

-- Strings.
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"', true)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Namespaces
local ns_boundary = lexer.alnum + S([[_/\]])
local word_char = lexer.alnum + S('_-')
lex:add_rule('namespace', token(lexer.FUNCTION, -B(ns_boundary + '(') * (lexer.alpha * word_char^0 * '.')^1 *
  (word_char + S('<>$'))^1 * -ns_boundary
))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, -B(lexer.digit) * lexer.number))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-*/%^=<>,.{}[]()')))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'start', 'end')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('#'))

return lex
