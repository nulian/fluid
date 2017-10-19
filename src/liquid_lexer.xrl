Definitions.

VARIABLE_START  = \{\{
VARIABLE_END    = \}\}
TAG_START       = \{\%
TAG_END         = \%\}
WHITESPACE      = ([\s\t\r\n]+)
STRING1         = '(\\\^.|\\.|[^'])*'
STRING2         = "(\\\^.|\\.|[^"])*"
ANYTHING        = [^{TAG_START}|{TAG_END}|{VARIABLE_START}|{VARIABLE_END}|'|"|\||,|:]*

Rules.

{WHITESPACE}      : {token, {whitespace, TokenLine, TokenChars}}.
{VARIABLE_START}  : {token, {'{{', TokenLine}}.
{VARIABLE_END}    : {token, {'}}', TokenLine}}.
{TAG_START}       : {token, {'{%', TokenLine}}.
{TAG_END}         : {token, {'%}', TokenLine}}.
\|                : {token, {'|', TokenLine}}.
,                 : {token, {',', TokenLine}}.
:                 : {token, {':', TokenLine}}.
\'                : {token, {'\'', TokenLine}}.
\"                : {token, {'"', TokenLine}}.
{STRING1}         : {token, {single_quoted_string, TokenLine, dequote(TokenChars, TokenLen)}}.
{STRING2}         : {token, {double_quoted_string, TokenLine, dequote(TokenChars, TokenLen)}}.
{ANYTHING}        : {token, {string, TokenLine, TokenChars}}.

Erlang code.

dequote(S,Len) -> lists:sublist(S, 2, Len - 2).
