%% -------------------------------------------------------------------
%%
%% DELETE command tests for the Parser
%%
%%
%% Copyright (c) 2016 Basho Technologies, Inc.  All Rights Reserved.
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

-module(parser_delete_tests).

-include_lib("eunit/include/eunit.hrl").
-include("parser_test_utils.hrl").

delete_sql_test() ->
    ?sql_comp_assert_match(
       "delete from argle where bish > 1", delete,
       [
        {table, <<"argle">>},
        {where, [
                 {'>', <<"bish">>, {integer, 1}}
                ]}
       ]).

