Nonterminals
liquid filters filter args arg variable object elements strings tags parse_plain_string element
cleaned_string maybe_whitespace strings_with_whitespace parse_whitespace_plain_string
.

Terminals
'{{' '}}' '{%' '%}' single_quoted_string double_quoted_string string '|' ':' ',' whitespace '\'' '"'
.

Rootsymbol liquid.

Nonassoc 100 string single_quoted_string double_quoted_string '|' ':' ',' '\'' '"' whitespace.

liquid -> elements : ['$1'].

elements -> element           : ['$1'].
elements -> element elements  : '$1' ++ '$2'.

element -> object                   : ['Elixir.Liquid.Variable':create('$1')].
element -> tags                     : ['Elixir.Liquid.Node':create('$1')].
element -> strings_with_whitespace  : [erlang:list_to_binary('$1')].

tags -> '{%' maybe_whitespace cleaned_string maybe_whitespace '%}' : {get_name('$3'), get_rest('$3')}.
tags -> '{%' maybe_whitespace cleaned_string maybe_whitespace strings_with_whitespace '%}' : {get_name('$3'), get_rest('$3') ++ '$5'}.

object -> '{{' '}}' : nil.
object -> '{{' maybe_whitespace variable maybe_whitespace '}}' : {'$3', []}.
object -> '{{' maybe_whitespace variable maybe_whitespace '|' maybe_whitespace filters maybe_whitespace '}}' : {'$3', '$7'}.

filters -> filter : ['$1'].
filters -> filter maybe_whitespace '|' filters : ['$1'|'$4'].

filter -> variable : {'$1', []}.
filter -> variable maybe_whitespace ':' maybe_whitespace args : {'$1','$5'}.

args -> arg maybe_whitespace : ['$1'].
args -> arg maybe_whitespace ',' maybe_whitespace args : ['$1'|'$5'].

arg -> variable : erlang:list_to_binary('$1').

variable -> string : trim(unwrap('$1')).
variable -> single_quoted_string : "'" ++ unwrap('$1') ++ "'".
variable -> double_quoted_string : "\"" ++ unwrap('$1') ++ "\"".

cleaned_string -> string : trim_leading(unwrap('$1')).

strings -> parse_plain_string         : ['$1'].
strings -> parse_plain_string strings : ['$1'|'$2'].

strings_with_whitespace -> parse_whitespace_plain_string                         : ['$1'].
strings_with_whitespace -> parse_whitespace_plain_string strings_with_whitespace : ['$1'|'$2'].

parse_whitespace_plain_string -> parse_plain_string : '$1'.
parse_whitespace_plain_string -> whitespace         : unwrap('$1').

parse_plain_string -> string                : unwrap('$1').
parse_plain_string -> single_quoted_string  : "'" ++ unwrap('$1') ++ "'".
parse_plain_string -> double_quoted_string  : "\"" ++ unwrap('$1') ++ "\"".
parse_plain_string -> '|'                   : "|".
parse_plain_string -> ':'                   : ":".
parse_plain_string -> ','                   : ",".
parse_plain_string -> '\''                  : "'".
parse_plain_string -> '"'                   : "\"".


maybe_whitespace -> whitespace : nil.
maybe_whitespace -> '$empty' : nil.

Erlang code.

unwrap({V, _}) -> V;
unwrap({_,_,V}) -> V.
trim(V) -> string:strip(V).
trim_leading(V) -> string:trim(V, leading).
get_name(V) -> trim(hd(string:split(V, " "))).
get_rest(V) -> tl(string:split(V, " ")).
