-- Copyright 2006-2020 Mitchell mitchell.att.foicica.com. See License.txt.
-- LPeg.re LPeg lexer.
-- Contributed by Alexander Misel.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S, B = lpeg.P, lpeg.R, lpeg.S, lpeg.B

local lex = lexer.new('lpeg')

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('--')))

local name = (lexer.alpha + '_') * (lexer.alnum + '_')^0

-- Classes
local defined = token(lexer.CLASS, P('%') * name)
local range = lexer.any * '-' * (lexer.any - ']')
local item = defined + token(lexer.DEFAULT, range + lexer.any)
lex:add_rule('class', token(lexer.DEFAULT, P('[') * P('^')^-1) * item * (-P(']') * item)^0 * ']')

-- Strings
local sq_str = lexer.range("'", nil, false)
local dq_str = lexer.range('"', nil, false)
local str = token(lexer.STRING, sq_str + dq_str)
lex:add_rule('string', str)

-- Numbers.
local number = token(lexer.NUMBER, lexer.number)
lex:add_rule('number', number)

-- Functions.
lex:add_rule('rcap', token(lexer.OPERATOR, S('-=~') * '>') * lexer.space^0 * (number + str + token(lexer.FUNCTION, name)) )

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('<-/&!+*=')))

lex:add_rule('defined', defined)

lex:add_rule('terminal', token(lexer.VARIABLE, name))

return lex
