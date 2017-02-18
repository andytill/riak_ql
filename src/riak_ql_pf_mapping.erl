%% -------------------------------------------------------------------
%%
%% riak_ql_pf_mapping: Riak Query Pipeline pipe fitting (pfitting)
%% column mapping datatype used in creating pfittings.
%%
%% Copyright (c) 2016-2017 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(riak_ql_pf_mapping).

%% TODO: constant or identifier should be split out as they are value, not
%% mapping
-type constant() :: {constant, term()}.
-export_type([constant/0]).
-type column_identifier() :: {identifier, [binary()]}.
-export_type([column_identifier/0]).

-type constant_or_identifier() :: constant() | column_identifier().
-export_type([constant_or_identifier/0]).

-type column_mapping_function() :: function() | undefined.
-export_type([column_mapping_function/0]).
-type column_mapping_function_args() :: [constant_or_identifier()].
-export_type([column_mapping_function_args/0]).

-type resolvable_field_type() :: riak_ql_ddl:external_field_type() | unresolved.
-export_type([resolvable_field_type/0]).

-record(column_mapping, {
          input_identifier :: column_identifier(),
          output_display_text :: binary(),
          output_type :: resolvable_field_type(),
          mapping_fun :: column_mapping_function(),
          mapping_fun_args :: column_mapping_function_args()
         }).
-opaque column_mapping() :: #column_mapping{}.
-export_type([column_mapping/0]).

-export([create/3,
         create/5,
         set_const_or_ident/1,
         get_const_or_ident/1,
         get_const_or_ident_type/1,
         set_column_ident/1,
         get_column_ident/1,
         set_constant/1,
         get_constant/1,
         get_column_mapping_fun/1,
         set_column_mapping_fun/1,
         get_column_mapping_fun_args/1,
         set_column_mapping_fun_args/1,
         get_resolvable_field_type/1,
         set_resolvable_field_type/1,
         get_input_identifier/1,
         get_output_type/1,
         get_display_text/1,
         get_fun/1,
         get_fun_args/1,
         nop_mapping/2,
         null_mapping/2,
         empty_args/0]).

-spec create(column_identifier(),
             binary(),
             resolvable_field_type()) -> column_mapping().
create(InputIdentifier, OutputDisplayText, OutputType) ->
    create(InputIdentifier, OutputDisplayText, OutputType,
           set_column_mapping_fun(fun nop_mapping/2), empty_args()).

-spec create(column_identifier(),
             binary(),
             resolvable_field_type(),
             column_mapping_function(),
             column_mapping_function_args()) -> column_mapping().
create(InputIdentifier, OutputDisplayText, OutputType, MappingFun, MappingFunArgs) ->
    #column_mapping{input_identifier = InputIdentifier,
                    output_display_text = OutputDisplayText,
                    output_type = OutputType,
                    mapping_fun = MappingFun,
                    mapping_fun_args = MappingFunArgs
                   }.

-spec get_input_identifier(column_mapping()) -> column_identifier().
get_input_identifier(#column_mapping{input_identifier = InputIdentifier}) -> InputIdentifier.

-spec get_output_type(column_mapping()) -> resolvable_field_type().
get_output_type(#column_mapping{output_type = OutputType}) -> OutputType.

-spec get_display_text(column_mapping()) -> binary().
get_display_text(#column_mapping{output_display_text=OutputDisplayText}) -> OutputDisplayText.

-spec get_fun(column_mapping()) -> column_mapping_function().
get_fun(#column_mapping{mapping_fun = MappingFun}) -> MappingFun.

-spec get_fun_args(column_mapping()) ->
  undefined | [constant_or_identifier()].
get_fun_args(#column_mapping{mapping_fun_args = MappingFunArgs}) -> MappingFunArgs.

-spec nop_mapping(column_mapping_function_args(),
                  column_mapping_function_args()) ->
  column_mapping_function().
nop_mapping(In, _Out) -> In.

-spec null_mapping(column_mapping_function_args(),
                  column_mapping_function_args()) ->
  column_mapping_function().
null_mapping(_In, _Out) -> undefined.

-spec get_const_or_ident(constant() | column_identifier()) -> constant_or_identifier().
get_const_or_ident(Constant = {constant, _C}) -> Constant;
get_const_or_ident(ColumnIdentifier = {identifier, [_Column]}) ->
    ColumnIdentifier.
-spec get_const_or_ident_type(constant_or_identifier()) ->
    {atom(), constant_or_identifier()}.
get_const_or_ident_type(Constant = {constant, _C}) -> {constant, Constant};
get_const_or_ident_type(ColumnIdentifier) -> {identifier, ColumnIdentifier}.

-spec set_const_or_ident(constant_or_identifier()) ->
    constant_or_identifier().
set_const_or_ident(Constant = {constant, _C}) -> Constant;
set_const_or_ident(ColumnIdentifier = {identifier, [_Column]}) ->
    ColumnIdentifier.

-spec set_column_ident(binary()) -> column_identifier().
set_column_ident(Column) -> {identifier, [Column]}.
-spec get_column_ident(column_identifier()) ->
    {identifier, [binary()]}.
get_column_ident(ColumnIdentifer = {identifier, [_Column]}) ->
    ColumnIdentifer.
-spec set_constant({constant, term()}) -> constant().
set_constant(Constant = {constant, _C}) -> Constant.
-spec get_constant(constant()) -> {constant, term()}.
get_constant(Constant = {constant, _C}) -> Constant.

-spec get_column_mapping_fun(column_mapping_function()) ->
    function() | undefined.
get_column_mapping_fun(F) -> F.
-spec set_column_mapping_fun(function() | undefined) ->
    column_mapping_function().
set_column_mapping_fun(F) -> F.

-spec empty_args() -> column_mapping_function_args().
empty_args() -> [].

-spec set_resolvable_field_type(riak_ql_ddl:external_field_type() | unresolved) ->
    resolvable_field_type().
set_resolvable_field_type(T) -> T.
-spec get_resolvable_field_type(resolvable_field_type()) ->
    riak_ql_ddl:external_field_type() | unresolved.
get_resolvable_field_type(T) -> T.

-spec get_column_mapping_fun_args(column_mapping_function_args()) ->
    [constant_or_identifier()].
get_column_mapping_fun_args(A) -> A.
-spec set_column_mapping_fun_args([constant_or_identifier()]) ->
    column_mapping_function_args().
set_column_mapping_fun_args(A) -> A.
