%% -*- erlang -*-
%%% @doc       Parser for the riak Time Series Query Language.
%%% @author    gguthrie@basho.com
%%% @copyright (C) 2016 Basho

Nonterminals

Statement
StatementWithoutSemicolon
Query
Select
Explain
Describe
ShowTables
Bucket
Buckets
Field
FieldElem
Fields
Identifier
Insert
CharacterLiteral
Where
Cond
Comp
Val
Vals
Funcall
TableDefinition
TableContentsSource
TableElementList
TableElements
TableElement
TableProperties
TablePropertyList
TableProperty
TablePropertyValue
ColumnDefinition
ColumnConstraint
KeyDefinition
DataType
KeyFieldList
KeyField
KeyFieldArgList
KeyFieldArg
NotNull
GroupBy

%% ValueExpression
%% CommonValueExpression

NumericValueExpression
Term
Factor
NumericPrimary

BooleanValueExpression
BooleanTerm
BooleanFactor
BooleanTest
TruthValue
BooleanPrimary
BooleanPredicand

CreateTable
PrimaryKey
FunArg
FunArgN

OptFieldList
IdentifierList
RowValueList
RowValue
FieldValue
.

Terminals

or_
and_
boolean
by
character_literal
comma
create
describe
double
equals_operator
explain
false
float
from
greater_than_operator
gte
identifier
insert
integer
into
group
key
limit
left_paren
less_than_operator
lte
asterisk
minus_sign
nomatch
not_
null
plus_sign
primary
quantum
regex
right_paren
select
semicolon
show
sint64
solidus
table
tables
timestamp
true
values
varchar
where
with
.

Rootsymbol Statement.
Endsymbol '$end'.

Statement -> StatementWithoutSemicolon : '$1'.
Statement -> StatementWithoutSemicolon semicolon : '$1'.

GroupBy -> group by Fields: {group_by, '$3'}.

StatementWithoutSemicolon -> Query           : convert('$1').
StatementWithoutSemicolon -> TableDefinition : fix_up_keys('$1').
StatementWithoutSemicolon -> Describe : '$1'.
StatementWithoutSemicolon -> Explain : '$1'.
StatementWithoutSemicolon -> Insert : '$1'.
StatementWithoutSemicolon -> ShowTables : '$1'.

Query -> Select limit integer : add_limit('$1', '$2', '$3').
Query -> Select               : '$1'.

Select -> select Fields from Bucket Where GroupBy 
                                          : make_select('$1', '$2', '$3', '$4', '$5', '$6').
Select -> select Fields from Bucket Where : make_select('$1', '$2', '$3', '$4', '$5').
Select -> select Fields from Bucket       : make_select('$1', '$2', '$3', '$4').

%% EXPLAIN STATEMENT
Explain -> explain Query : make_explain('$2').

%% 20.9 DESCRIBE STATEMENT
Describe -> describe Bucket : make_describe('$2').

Insert -> insert into Identifier OptFieldList values RowValueList : make_insert('$3', '$4', '$6').

Where -> where BooleanValueExpression : make_where('$1', '$2').

Fields -> Fields     comma   FieldElem   : concat_select('$1', '$3').
Fields -> FieldElem                      : '$1'.

FieldElem -> Field : '$1'.
FieldElem -> Val   : '$1'.

Field -> NumericValueExpression : '$1'.
%Field -> Identifier    : canonicalise_col('$1').
Field -> asterisk : make_wildcard('$1').

%% Support early error on multi-table select
Buckets -> Bucket comma Bucket : make_list('$1', '$3').

Bucket -> Identifier   : '$1'.

Identifier -> identifier : '$1'.

CharacterLiteral -> character_literal : character_literal_to_binary('$1').

FunArg -> NumericValueExpression : '$1'.
FunArg -> Val        : '$1'.
%% FunArg -> Funcall    : '$1'.

FunArgN -> comma FunArg         : ['$2'].
FunArgN -> comma FunArg FunArgN : ['$2' , '$3'].

Funcall -> Identifier left_paren                right_paren : make_funcall('$1', []).
Funcall -> Identifier left_paren FunArg         right_paren : make_funcall('$1', ['$3']).
Funcall -> Identifier left_paren asterisk       right_paren : make_funcall('$1', ['$3']).
Funcall -> Identifier left_paren FunArg FunArgN right_paren : make_funcall('$1', ['$3'] ++ '$4').

Cond -> Vals Comp Vals : make_expr('$1', '$2', '$3').

Vals -> NumericValueExpression : '$1'.
Vals -> regex            : '$1'.
Vals -> Val              : '$1'.

Val -> varchar            : '$1'.
Val -> CharacterLiteral   : '$1'.
Val -> TruthValue         : '$1'.

%% Comp -> approx    : '$1'.
Comp -> equals_operator        : '$1'.
Comp -> greater_than_operator  : '$1'.
Comp -> less_than_operator     : '$1'.
Comp -> gte                    : '$1'.
Comp -> lte                    : '$1'.
%% Comp -> ne                  : '$1'.
Comp -> nomatch                : '$1'.
%% Comp -> notapprox           : '$1'.

CreateTable -> create table : create_table.

ShowTables -> show tables : [{type, show_tables}].

NotNull -> not_ null : '$1'.

%% %% 6.26 VALUE EXPRESSION

%% ValueExpression -> CommonValueExpression : '$1'.
%% ValueExpression -> BooleanValueExpression : '$1'.

%% CommonValueExpression ->
%%     NumericValueExpression : '$1'.
%% % todo: 6.29 string value expression
%% CommonValueExpression ->
%%     character_literal : '$1'.

%% 6.27 NUMERIC VALUE EXPRESSION

NumericValueExpression -> Term : '$1'.
NumericValueExpression ->
    NumericValueExpression plus_sign Term :
        make_expr('$1', '$2', '$3').
NumericValueExpression ->
    NumericValueExpression minus_sign Term :
        make_expr('$1', '$2', '$3').

Term -> Factor : '$1'.
Term ->
    Term asterisk Factor :
        make_expr('$1', '$2', '$3').
Term ->
    Term solidus Factor :
        make_expr('$1', '$2', '$3').

Factor -> NumericPrimary : '$1'.
Factor -> plus_sign NumericPrimary : '$2'.
Factor -> minus_sign NumericPrimary : {negate, '$2'}.

NumericPrimary -> integer identifier : add_unit('$1', '$2').
NumericPrimary -> integer : '$1'.
NumericPrimary -> float : '$1'.
NumericPrimary -> Identifier : '$1'.
NumericPrimary -> Funcall : '$1'.
NumericPrimary -> left_paren NumericValueExpression right_paren : '$2'.
% NumericPrimary -> NumericValueFunction : '$1'.

%% 6.35 BOOLEAN VALUE EXPRESSION

BooleanValueExpression -> BooleanTerm : '$1'.
BooleanValueExpression ->
    BooleanValueExpression or_ BooleanTerm :
        {expr, {or_, '$1', '$3'}}.

BooleanTerm -> BooleanFactor : '$1'.
BooleanTerm ->
    BooleanTerm and_ BooleanFactor :
        {expr, {and_, '$1', '$3'}}.

BooleanFactor -> BooleanTest : '$1'.
BooleanFactor -> not_ BooleanTest : {not_, '$1'}.

BooleanTest -> BooleanPrimary : '$1'.
%% i guess we don't have IS right now?
%% BooleanTest -> BooleanPrimary is TruthValue : {'=', '$1', '$3'}.
%% BooleanTest -> BooleanPrimary is not_ TruthValue : {'<>', '$1', '$4'}.

TruthValue -> true : {boolean, true}.
TruthValue -> false : {boolean, false}.

BooleanPrimary -> BooleanPredicand : '$1'.

BooleanPredicand ->
    Cond : '$1'.
BooleanPredicand ->
    left_paren BooleanValueExpression right_paren : '$2'.

%% TABLE DEFINTITION

TableDefinition ->
    CreateTable Bucket TableContentsSource :
        make_table_definition('$2', '$3').
TableDefinition ->
    CreateTable Bucket TableContentsSource with TableProperties :
        make_table_definition('$2', '$3', '$5').

TableContentsSource -> TableElementList : '$1'.
TableElementList -> left_paren TableElements right_paren : '$2'.

TableElements ->
    TableElement comma TableElements : make_table_element_list('$1', '$3').
TableElements -> TableElement        : make_table_element_list('$1').

TableElement -> ColumnDefinition : '$1'.
TableElement -> KeyDefinition : '$1'.

ColumnDefinition ->
    Identifier DataType ColumnConstraint : make_column('$1', '$2', '$3').
ColumnDefinition ->
    Identifier DataType : make_column('$1', '$2').

ColumnConstraint -> NotNull : not_null.

DataType -> double    : '$1'.
DataType -> sint64    : '$1'.
DataType -> timestamp : '$1'.
DataType -> varchar   : '$1'.
DataType -> boolean   : '$1'.

PrimaryKey -> primary key : primary_key.

KeyDefinition ->
    PrimaryKey left_paren KeyFieldList right_paren : make_local_key('$3').
KeyDefinition ->
    PrimaryKey left_paren left_paren KeyFieldList right_paren comma KeyFieldList right_paren : make_partition_and_local_keys('$4', '$7').

KeyFieldList -> KeyField comma KeyFieldList : make_list('$3', '$1').
KeyFieldList -> KeyField : make_list({list, []}, '$1').

KeyField -> quantum left_paren KeyFieldArgList right_paren : make_modfun(quantum, '$3').
KeyField -> Identifier : '$1'.

KeyFieldArgList ->
    KeyFieldArg comma KeyFieldArgList : make_list('$3', '$1').
KeyFieldArgList ->
    KeyFieldArg : make_list({list, []}, '$1').

KeyFieldArg -> integer : '$1'.
KeyFieldArg -> float   : '$1'.
KeyFieldArg -> CharacterLiteral    : '$1'.
KeyFieldArg -> Identifier : '$1'.
%% KeyFieldArg -> atom left_paren Word right_paren : make_atom('$3').

OptFieldList -> left_paren IdentifierList right_paren : '$2'.
OptFieldList -> '$empty' : undefined.

IdentifierList -> IdentifierList comma Identifier : '$1' ++ ['$3'].
IdentifierList -> Identifier : ['$1'].

RowValueList -> left_paren right_paren : [[]].
RowValueList -> left_paren RowValue right_paren : ['$2'].
RowValueList -> RowValueList comma left_paren RowValue right_paren : '$1' ++ ['$4'].

RowValue -> RowValue comma FieldValue : '$1' ++ ['$3'].
RowValue -> FieldValue : ['$1'].

FieldValue -> integer : '$1'.
FieldValue -> float : '$1'.
FieldValue -> TruthValue : '$1'.
FieldValue -> CharacterLiteral : '$1'.
FieldValue -> Identifier : '$1'.

TableProperties ->
    left_paren TablePropertyList right_paren : '$2'.

TablePropertyList ->
    '$empty' : [].
TablePropertyList ->
    TableProperty : prepend_table_proplist([], '$1').
TablePropertyList ->
    TableProperty comma TablePropertyList : prepend_table_proplist('$3', '$1').

TableProperty ->
    identifier equals_operator TablePropertyValue :
        make_table_property('$1', '$3').

TablePropertyValue -> identifier : '$1'.   %% this is not valid
%% the above rule is just to produce a specific error message
TablePropertyValue -> TruthValue : '$1'.
TablePropertyValue -> integer : '$1'.
TablePropertyValue -> float : '$1'.
TablePropertyValue -> character_literal : '$1'.

Erlang code.

-record(outputs,
        {
          type :: create | describe | explain | insert | select,
          buckets = [],
          fields  = [],
          limit   = [],
          where   = [],
          ops     = [],
          group_by
         }).

-include("riak_ql_ddl.hrl").

%% export the return value function to prevent xref errors
%% this fun is used during the parsing and is marked as
%% unused/but not to be exported in the yecc source
%% no way to stop rebar borking on it AFAIK
-export([
         return_error/2,
         ql_parse/1,
         canonicalise_where/1
         ]).

%% Provide more useful success tuples
ql_parse(Tokens) ->
    interpret_parse_result(parse(Tokens)).

interpret_parse_result({error, _}=Err) ->
    Err;
interpret_parse_result({ok, {?DDL{}=DDL, Props}}) ->
    {ddl, DDL, Props};
interpret_parse_result({ok, Proplist}) ->
    extract_type(proplists:get_value(type, Proplist), Proplist).

extract_type(Type, Proplist) ->
    {Type, Proplist -- [{type, Type}]}.

%% if no partition key is specified hash on the local key
fix_up_keys(?DDL{partition_key = none, local_key = LK} = DDL) ->
    DDL?DDL{partition_key = LK, local_key = LK};
fix_up_keys(A) ->
    A.

convert(#outputs{type    = select,
                 buckets = B,
                 fields  = F,
                 limit   = L,
                 where   = W,
                 group_by = G} = Outputs) ->
    ok = validate_select_query(Outputs),
    [
     {type, select},
     {tables, B},
     {fields, F},
     {limit, L},
     {where, W},
     {group_by, G}
    ];
convert(#outputs{type = create} = O) ->
    O.

validate_select_query(Outputs) ->
    ok = assert_group_by_select(Outputs),
    ok = assert_group_by_is_valid(Outputs).

%% If the query uses GROUP BY then check that the identifiers in the select
%% all exist in the GROUP BY.
assert_group_by_select(#outputs{ group_by = [] }) ->
    ok;
assert_group_by_select(#outputs{ fields = Fields, group_by = GroupBy }) ->
    Identifiers = lists:flatten(
        [lists:reverse(find_group_identifiers(ColumnSelect, [])) || ColumnSelect <- Fields]),
    IllegalIdentifiers =
        [to_identifier_name(Identifier)|| Identifier <- Identifiers, not is_identifier_in_groups(Identifier, GroupBy)],
    case IllegalIdentifiers of
        [] ->
            ok;
        _ ->
            return_error_flat("Field(s) " ++ string:join(IllegalIdentifiers,", ") ++ " are specified in the select statement but not the GROUP BY.")
    end.


%%
assert_group_by_is_valid(#outputs{ group_by = GroupBy }) ->
    case lists:member({identifier, [<<"*">>]}, GroupBy) of
        false ->
            ok;
        true ->
            return_error_flat("GROUP BY can only contain table columns but '*' was found.")
    end.

%%
is_identifier_in_groups({identifier, [F]}, GroupBy) ->
    lists:member({identifier, F}, GroupBy);
is_identifier_in_groups(Identifier, GroupBy) ->
    lists:member(Identifier, GroupBy).

%% Identifier field name as a string.
to_identifier_name({identifier, [F]}) ->
    binary_to_list(F);
to_identifier_name({identifier, F}) ->
    binary_to_list(F).

%% Recurse through a column in the select clause to find identifiers that must
%% be specified in the GROUP BY.
find_group_identifiers({identifier, [<<"*">>]} = Identifier, Acc) ->
    [Identifier|Acc];
find_group_identifiers({identifier, _} = Identifier, Acc) ->
    [Identifier|Acc];
find_group_identifiers({negate, Expr}, Acc) ->
    find_group_identifiers(Expr, Acc);
find_group_identifiers({Op, Left, Right}, Acc) when is_atom(Op) ->
    find_group_identifiers(Right, find_group_identifiers(Left, Acc));
find_group_identifiers({{window_agg_fn, _}, _}, Acc) ->
    %% identifiers in aggregate functions are ok
    Acc;
find_group_identifiers({_, _}, Acc) ->
    Acc.

make_select({select, multi_table_error}, _B, _C, _D) ->
    return_error(0, <<"Must provide exactly one table name">>);
make_select(A, B, C, D) ->
    make_select(A, B, C, D, {where, []}).

make_select(A, B, C, D, E) -> make_select(A, B, C, D, E, {group_by, []}).

make_select({select, _SelectBytes},
            Select,
            {from, _FromBytes},
            {Type, D},
            {_Where, E},
            {group_by, GroupFields}) ->
    Bucket = case Type of
                 identifier -> D;
                 list   -> {list, [X || X <- D]};
                 regex  -> {regex, D}
             end,
    FieldsAsList = case is_list(Select) of
                       true  -> Select;
                       false -> [Select]
                   end,
    FieldsWithoutExprs = [remove_exprs(X) || X <- FieldsAsList],
    FieldsWrappedIdentifiers = [wrap_identifier(X) || X <- FieldsWithoutExprs],
    #outputs{type    = select,
             fields  = FieldsWrappedIdentifiers,
             buckets = Bucket,
             where   = E,
             group_by = lists:flatten([GroupFields])
            }.


wrap_identifier({identifier, IdentifierName})
  when is_binary(IdentifierName) ->
    {identifier, [IdentifierName]};
wrap_identifier(Default) -> Default.

make_describe({identifier, D}) ->
    [
     {type, describe},
     {identifier, D}
    ].

%% For explain just change the output type
make_explain(#outputs{type = select} = S) ->
    Props = convert(S),
    lists:keyreplace(type, 1, Props, {type, explain}).

make_insert({identifier, Table}, Fields, Values) ->
    FieldsAsList = case is_list(Fields) of
                       true  -> Fields;
                       false -> []
                   end,
    FieldsWrappedIdentifiers = [wrap_identifier(X) || X <- FieldsAsList],
    [
     {type, insert},
     {table, Table},
     {fields, FieldsWrappedIdentifiers},
     {values, Values}
    ].

add_limit(A, _B, {integer, C}) ->
    A#outputs{limit = C}.

make_expr({LiteralFlavor, Literal},
          {Op, _},
          {identifier, IdentifierName}) when LiteralFlavor /= identifier ->
    % if the literal is on left hand side then rewrite the expression, putting
    % on the right, this means flipping greater than to less than and vice versa
    FlippedComparison = maybe_flip_op(Op),
    make_expr({identifier, IdentifierName},
              {FlippedComparison, <<"flipped">>},
              {LiteralFlavor, Literal});
make_expr({TypeA, A}, {B, _}, {Type, C}) ->
    B1 = case B of
             and_                   -> and_;
             or_                    -> or_;
             plus_sign              -> '+';
             minus_sign             -> '-';
             asterisk               -> '*';
             solidus                -> '/';
             greater_than_operator  -> '>';
             less_than_operator     -> '<';
             gte                    -> '>=';
             lte                    -> '<=';
             equals_operator        -> '=';
             ne                     -> '<>';
             approx                 -> '=~';
             notapprox              -> '!~';
             nomatch                -> '!='
         end,
    C2 = case Type of
             expr -> C;
             _    -> {Type, C}
         end,
    {expr, {B1, {TypeA, A}, C2}}.

make_wildcard({asterisk, <<"*">>}) -> {identifier, [<<"*">>]}.

make_where({where, A}, {expr, B}) ->
    NewB = remove_exprs(B),
    {A, [canonicalise_where(NewB)]}.

maybe_flip_op(less_than_operator)    -> greater_than_operator;
maybe_flip_op(greater_than_operator) -> less_than_operator;
maybe_flip_op(lte)                   -> gte;
maybe_flip_op(gte)                   -> lte;
maybe_flip_op(Op)                    -> Op.

%%
%% rewrite the where clause to have a canonical form
%% makes query rewriting easier
%%
canonicalise_where(WhereClause) ->
    Canonical = canon2(WhereClause),
    _NewWhere = hoist(Canonical).

canon2({Cond, A, B}) when is_binary(B) andalso not is_binary(A) ->
    canonicalize_condition_order({Cond, B, A});
canon2({Cond, A, B}) when Cond =:= and_ orelse
                          Cond =:= or_  ->
    %% this is stack busting non-tail recursion
    %% but our where clauses are bounded in size so thats OK
    A1 = canon2(A),
    B1 = canon2(B),
    case A1 == B1 of
        true ->
            A1;
        false ->
            case is_lower(A1, B1) of
                true  -> {Cond, A1, B1};
                false -> {Cond, B1, A1}
            end
    end;
canon2({Op, A, B}) ->
    {Op, strip(A), strip(B)};
canon2(A) ->
    A.

strip({identifier, A}) -> A;
strip(A)               -> A.

-spec canonicalize_condition_order({atom(), any(), binary()}) -> {atom(), binary(), any()}.
canonicalize_condition_order({'>', Reference, Column}) ->
    canon2({'<', Column, Reference});
canonicalize_condition_order({'<', Reference, Column}) ->
    canon2({'>', Column, Reference}).

hoist({and_, {and_, A, B}, C}) ->
    Hoisted = {and_, A, hoist({and_, B, C})},
    _Sort = sort(Hoisted);
hoist({A, B, C}) ->
    B2 = case B of
             {and_, _, _} -> hoist(B);
             _            -> B
         end,
    C2 = case C of
             {and_, _, _} -> hoist(C);
             _            -> C
         end,
    {A, B2, C2}.

%% a truly horendous bubble sort algo which is also
%% not tail recursive
sort({and_, A, {and_, B, C}}) ->
    case is_lower(A, B) of
        true ->
            {and_, B1, C1} = sort({and_, B, C}),
            case is_lower(A, B1) of
                true  -> {and_, A, {and_, B1, C1}};
                false -> sort({and_, B1, {and_, A, C1}})
            end;
        false ->
            sort({and_, B, sort({and_, A, C})})
    end;
sort({and_, A, A}) ->
    A;
sort({Op, A, B}) ->
    case is_lower(A, B) of
        true  -> {Op, A, B};
        false -> {Op, B, A}
    end.

is_lower(Ands, {_, _, _}) when is_list(Ands)->
    true;
is_lower({_, _, _}, Ands) when is_list(Ands)->
    true;
is_lower(Ands1, Ands2) when is_list(Ands1) andalso is_list(Ands2) ->
    true;
is_lower({Op1, _, _} = A, {Op2, _, _} = B) when (Op1 =:= and_ orelse
                                         Op1 =:= or_  orelse
                                         Op1 =:= '>'  orelse
                                         Op1 =:= '<'  orelse
                                         Op1 =:= '>=' orelse
                                         Op1 =:= '<=' orelse
                                         Op1 =:= '='  orelse
                                         Op1 =:= '<>' orelse
                                         Op1 =:= '=~' orelse
                                         Op1 =:= '!~' orelse
                                         Op1 =:= '!=')
                                        andalso
                                        (Op2 =:= and_ orelse
                                         Op2 =:= or_  orelse
                                         Op2 =:= '>'  orelse
                                         Op2 =:= '<'  orelse
                                         Op2 =:= '>=' orelse
                                         Op2 =:= '<=' orelse
                                         Op2 =:= '='  orelse
                                         Op2 =:= '<>' orelse
                                         Op2 =:= '=~' orelse
                                         Op2 =:= '!~' orelse
                                         Op2 =:= '!=') ->
    (A =< B).

remove_exprs({expr, A}) ->
    remove_exprs(A);
remove_exprs({A, B, C}) ->
    {A, remove_exprs(B), remove_exprs(C)};
remove_exprs(A) ->
    A.

%% Functions are disabled so return an error.
make_funcall({identifier, FuncName}, Args) ->
    Fn = canonicalise_window_aggregate_fn(FuncName),
    case get_func_type(Fn) of
        window_aggregate_fn ->
            %% FIXME this should be in the type checker in riak_kv_qry_compiler
            {Fn2, Args2} = case {Fn, Args} of
                               {'COUNT', [{asterisk, _Asterisk}]} ->
                                   {'COUNT', [{identifier, <<"*">>}]};
                               {_, [{asterisk, _Asterisk}]} ->
                                   Msg1 = io_lib:format("Function '~s' does not support"
                                                        " wild cards args.", [Fn]),
                                   return_error(0, iolist_to_binary(Msg1));
                               _ ->
                                   {Fn, Args}
                           end,
            Args3 = [canonicalise_expr(X) || X <- Args2],
            {{window_agg_fn, Fn2}, Args3};
        not_supported ->
            Msg2 = io_lib:format("Function not supported - '~s'.", [FuncName]),
            return_error(0, iolist_to_binary(Msg2))
    end;
make_funcall(_, _) ->
    % make dialyzer stop erroring on no local return.
    error.

canonicalise_expr({identifier, X}) ->
    {identifier, [X]};
canonicalise_expr({expr, X}) ->
    X;
canonicalise_expr(X) ->
    X.

get_func_type(FuncName) when FuncName =:= 'AVG'    orelse
                             FuncName =:= 'MEAN'   orelse
                             FuncName =:= 'SUM'    orelse
                             FuncName =:= 'COUNT'  orelse
                             FuncName =:= 'MIN'    orelse
                             FuncName =:= 'MAX'    orelse
                             FuncName =:= 'STDDEV' orelse
                             FuncName =:= 'STDDEV_SAMP' orelse
                             FuncName =:= 'STDDEV_POP' ->
    window_aggregate_fn;
get_func_type(FuncName) when is_atom(FuncName) ->
    not_supported.

%% TODO
%% this list to atom needs to change to list to existing atom
%% once the fns that actually execute the Window_Aggregates Fns are written then the atoms
%% will definetely be existing - but just not now
%% also try/catch round it
canonicalise_window_aggregate_fn(Fn) when is_binary(Fn)->
     list_to_atom(string:to_upper(binary_to_list(Fn))).

%% canonicalise_col({identifier, X}) -> {identifier, [X]};
%% canonicalise_col(X)               -> X.

character_literal_to_binary({character_literal, CharacterLiteralBytes})
  when is_binary(CharacterLiteralBytes) ->
    {binary, CharacterLiteralBytes}.

%%
add_unit({Type, Value}, {identifier, Unit1}) ->
    Unit2 = list_to_binary(string:to_lower(binary_to_list(Unit1))),
    case riak_ql_quanta:unit_to_millis(Value, Unit2) of
        error ->
            return_error_flat(io_lib:format(
                "Used ~s as a measure of time in ~p~s. Only s, m, h and d are allowed.",
                [Unit2, Value, Unit2]
            ));
        Millis ->
            {Type, Millis}
    end.

concat_select(L1, L2) when is_list(L1) andalso
                           is_list(L2) ->
    L1 ++ L2;
concat_select(L1, El2) when is_list(L1) ->
    L1 ++ [El2];
concat_select(El1, El2) ->
    [El1, El2].

make_list({list, A}, {_, B}) ->
    {list, A ++ [B]};
make_list({_T1, A}, {_T2, B}) ->
    {list, [A, B]}.

make_column({identifier, FieldName}, {DataType, _}) ->
    #riak_field_v1{
       name     = FieldName,
       type     = DataType,
       optional = true}.

make_column({identifier, FieldName}, {DataType, _}, not_null) ->
    #riak_field_v1{
       name     = FieldName,
       type     = DataType,
       optional = false}.

%% if only the local key is defined
%% use it as the partition key as well
make_local_key(FieldList) ->
    Key = #key_v1{ast = lists:reverse(extract_key_field_list(FieldList, []))},
    [
     {partition_key, Key},
     {local_key,     Key}
    ].

make_partition_and_local_keys(PFieldList, LFieldList) ->
    PFields = lists:reverse(extract_key_field_list(PFieldList, [])),
    LFields = lists:reverse(extract_key_field_list(LFieldList, [])),
    [
     {partition_key, #key_v1{ast = PFields}},
     {local_key,     #key_v1{ast = LFields}}
    ].

make_table_element_list(A) ->
    {table_element_list, [A]}.

make_table_element_list(A, {table_element_list, B}) ->
    {table_element_list, [A] ++ lists:flatten(B)};
make_table_element_list(A, B) ->
    {table_element_list, lists:flatten([A, B])}.

extract_key_field_list({list, []}, Extracted) ->
    Extracted;
extract_key_field_list({list,
                        [Modfun = #hash_fn_v1{} | Rest]},
                       Extracted) ->
    [Modfun | extract_key_field_list({list, Rest}, Extracted)];
extract_key_field_list({list, [Field | Rest]}, Extracted) ->
    [?SQL_PARAM{name = [Field]} |
     extract_key_field_list({list, Rest}, Extracted)].

make_table_definition(TableName, Contents) ->
    make_table_definition(TableName, Contents, []).
make_table_definition({identifier, Table}, Contents, Properties) ->
    {validate_ddl(
       ?DDL{table = Table,
            partition_key = find_partition_key(Contents),
            local_key = find_local_key(Contents),
            fields = find_fields(Contents)}),
     validate_table_properties(Properties)}.

find_partition_key({table_element_list, Elements}) ->
    find_partition_key(Elements);
find_partition_key([{partition_key, Key} | _Rest]) ->
    Key;
find_partition_key([_Head | Rest]) ->
    find_partition_key(Rest);
find_partition_key(_) ->
    none.

find_local_key({table_element_list, Elements}) ->
    find_local_key(Elements);
find_local_key([{local_key, Key} | _Rest]) ->
    Key;
find_local_key([_Head | Rest]) ->
    find_local_key(Rest);
find_local_key(_) ->
    none.

make_modfun(quantum, {list, Args}) ->
    [Param, Quantity, Unit] = lists:reverse(Args),
    {modfun, #hash_fn_v1{
                mod  = riak_ql_quanta,
                fn   = quantum,
                args = [?SQL_PARAM{name = [Param]}, Quantity, binary_to_existing_atom(Unit, utf8)],
                type = timestamp
               }}.

find_fields({table_element_list, Elements}) ->
    find_fields(1, Elements, []).

find_fields(_Count, [], Found) ->
    lists:reverse(Found);
find_fields(Count, [Field = #riak_field_v1{} | Rest], Elements) ->
    PositionedField = Field#riak_field_v1{position = Count},
    find_fields(Count + 1, Rest, [PositionedField | Elements]);
find_fields(Count, [_Head | Rest], Elements) ->
    find_fields(Count, Rest, Elements).

prepend_table_proplist(L, P) ->
    [P | L].

make_table_property({identifier, K}, {Type, _V})
  when Type == identifier ->
    return_error(
      0, iolist_to_binary(
           io_lib:format("Expecting a numeric, boolean or string value for WITH property \"~s\""
                         " (did you forget to quote a string?)", [K])));
make_table_property({identifier, K}, {Type, V})
  when Type == boolean;
       Type == integer;
       Type == float;
       Type == character_literal ->
    {K, V}.

validate_table_properties(Properties) ->
    %% We let all k=v in: there's more substantial validation and
    %% enrichment happening in riak_kv_wm_utils:erlify_bucket_prop
    Properties.


%% DDL validation

validate_ddl(DDL) ->
    ok = assert_keys_present(DDL),
    ok = assert_unique_fields_in_pk(DDL),
    ok = assert_partition_key_length(DDL),
    ok = assert_primary_and_local_keys_match(DDL),
    ok = assert_partition_key_fields_exist(DDL),
    ok = assert_primary_key_fields_non_null(DDL),
    ok = assert_not_more_than_one_quantum(DDL),
    ok = assert_quantum_fn_args(DDL),
    ok = assert_quantum_is_last_in_partition_key(DDL),
    DDL.

%% @doc Ensure DDL has keys
assert_keys_present(?DDL{local_key = LK, partition_key = PK})
  when LK == none;
       PK == none ->
    return_error_flat("Missing primary key");
assert_keys_present(_GoodDDL) ->
    ok.

%% @doc Ensure all fields appearing in PRIMARY KEY are not null.
assert_primary_key_fields_non_null(?DDL{local_key = #key_v1{ast = LK},
                                        fields = Fields}) ->
    PKFieldNames = [N || ?SQL_PARAM{name = [N]} <- LK],
    OnlyPKFields = [F || #riak_field_v1{name = N} = F <- Fields,
                         lists:member(N, PKFieldNames)],
    NonNullFields =
        [binary_to_list(F) || #riak_field_v1{name = F, optional = Null}
                                  <- OnlyPKFields, Null == true],
    case NonNullFields of
        [] ->
            ok;
        NonNullFields ->
            return_error_flat("Primary key has 'null' fields (~s)",
                              [string:join(NonNullFields, ", ")])
    end.

%% @doc Assert that the partition key has at least one field.
assert_partition_key_length(?DDL{partition_key = {key_v1, [_|_]}}) ->
    ok;
assert_partition_key_length(?DDL{partition_key = {key_v1, Key}}) ->
    return_error_flat("Primary key must have one or more fields ~p", [Key]).

%% @doc Verify primary key and local partition have the same elements
assert_primary_and_local_keys_match(?DDL{partition_key = #key_v1{ast = Primary},
                                         local_key = #key_v1{ast = Local}}) ->
    PrimaryList = [query_field_name(F) || F <- Primary],
    LocalList = [query_field_name(F) || F <- lists:sublist(Local, length(PrimaryList))],
    case PrimaryList == LocalList of
        true ->
            ok;
        false ->
            return_error_flat("Local key does not match primary key")
    end.

assert_unique_fields_in_pk(?DDL{local_key = #key_v1{ast = LK}}) ->
    Fields = [N || ?SQL_PARAM{name = [N]} <- LK],
    case length(Fields) == length(lists:usort(Fields)) of
        true ->
            ok;
        false ->
            return_error_flat(
              "Primary key has duplicate fields (~s)",
              [string:join(
                 which_duplicate(
                   lists:sort(
                     [binary_to_list(F) || F <- Fields])),
                 ", ")])
    end.

%% Ensure that all fields in the primary key exist in the table definition.
assert_partition_key_fields_exist(?DDL{ fields = Fields,
                                         partition_key = #key_v1{ ast = PK } }) ->
    MissingFields =
        [binary_to_list(name_of(F)) || F <- PK, not is_field(F, Fields)],
    case MissingFields of
        [] ->
            ok;
        _ ->
            return_error_flat("Primary key includes non-existent fields (~s).",
                              [string:join(MissingFields, ", ")])
    end.

assert_quantum_fn_args(#ddl_v1{ partition_key = #key_v1{ ast = PKAST } } = DDL) ->
    [assert_quantum_fn_args2(DDL, Args) || #hash_fn_v1{ mod = riak_ql_quanta, fn = quantum, args = Args } <- PKAST],
    ok.

%% The param argument is validated by assert_partition_key_fields_exist/1.
assert_quantum_fn_args2(DDL, [Param, Unit, Measure]) ->
    FieldName = name_of(Param),
    case riak_ql_ddl:get_field_type(DDL, FieldName) of
        {ok, timestamp} ->
            ok;
        {ok, InvalidType} ->
            return_error_flat("Quantum field '~s' must be type of timestamp but was ~p.",
                              [FieldName, InvalidType])
    end,
    case lists:member(Measure, [d,h,m,s]) of
        true ->
            ok;
        false ->
            return_error_flat("Quantum time measure was ~p but must be d, h, m or s.",
                              [Measure])
    end,
    case is_integer(Unit) andalso Unit >= 1 of
        true ->
            ok;
        false ->
            return_error_flat("Quantum time unit must be a positive integer.", [])
    end.

assert_not_more_than_one_quantum(#ddl_v1{ partition_key = #key_v1{ ast = PKAST } }) ->
    QuantumFns =
        [Fn || #hash_fn_v1{ } = Fn <- PKAST],
    case length(QuantumFns) =< 1 of
        true ->
            ok;
        false ->
            return_error_flat(
                "More than one quantum function in the partition key.", [])
    end.

assert_quantum_is_last_in_partition_key(#ddl_v1{ partition_key = #key_v1{ ast = PKAST } }) ->
    assert_quantum_is_last_in_partition_key2(PKAST).

%%
assert_quantum_is_last_in_partition_key2([]) ->
    ok;
assert_quantum_is_last_in_partition_key2([#hash_fn_v1{ }]) ->
    ok;
assert_quantum_is_last_in_partition_key2([#hash_fn_v1{ }|_]) ->
    return_error_flat(
        "The quantum function must be the last element of the partition key.", []);
assert_quantum_is_last_in_partition_key2([_|Tail]) ->
    assert_quantum_is_last_in_partition_key2(Tail).

%% Check that the field name exists in the list of fields.
is_field(Field, Fields) ->
    (lists:keyfind(name_of(Field), 2, Fields) /= false).

%%
name_of(?SQL_PARAM{ name = [N] }) ->
    N;
name_of(#hash_fn_v1{ args = [?SQL_PARAM{ name = [N] }|_] }) ->
    N.

which_duplicate(FF) ->
    which_duplicate(FF, []).
which_duplicate([], Acc) ->
    Acc;
which_duplicate([_], Acc) ->
    Acc;
which_duplicate([A,A|_] = [_|T], Acc) ->
    which_duplicate(T, [A|Acc]);
which_duplicate([_|T], Acc) ->
    which_duplicate(T, Acc).

%% Pull the name out of the appropriate record
query_field_name(#hash_fn_v1{args = Args}) ->
    Param = lists:keyfind(?SQL_PARAM_RECORD_NAME, 1, Args),
    query_field_name(Param);
query_field_name(?SQL_PARAM{name = Field}) ->
    Field.

-spec return_error_flat(string()) -> no_return().
return_error_flat(F) ->
    return_error_flat(F, []).
-spec return_error_flat(string(), [term()]) -> no_return().
return_error_flat(F, A) ->
    return_error(
      0, iolist_to_binary(io_lib:format(F, A))).
