-- LPeg.re LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S, B = lpeg.P, lpeg.R, lpeg.S, lpeg.B

local lex = lexer.new('tpl')

local name = lexer.alpha * (P('_') + lexer.alnum)^0
-- Functions.
lex:add_rule('func_call', token(lexer.OPERATOR, '@')
  * token(lexer.CLASS, name) * (P(':') * token(lexer.FUNCTION, name))^-1 )

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, P('$') * 
  (P('[') * (lexer.any - ']' - '\n')^1 * ']' + (P('_') + lexer.alnum)^1)
))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('(){}')))

lex:add_fold_point(lexer.OPERATOR, '(', ')')

return lex
