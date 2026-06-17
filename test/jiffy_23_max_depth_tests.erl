% This file is part of Jiffy released under the MIT license.
% See the LICENSE file for more information.

-module(jiffy_23_max_depth_tests).


-include_lib("eunit/include/eunit.hrl").
-include("jiffy_util.hrl").


%% A nested array of the given depth, e.g. depth 3 -> <<"[[[]]]">>.
nested_array(Depth) ->
    iol2b([lists:duplicate(Depth, $[), lists:duplicate(Depth, $])]).

%% A nested object of the given depth, e.g. depth 2 -> <<"{\"a\":{\"a\":1}}">>.
nested_object(1) ->
    <<"{\"a\":1}">>;
nested_object(Depth) ->
    iol2b([<<"{\"a\":">>, nested_object(Depth - 1), <<"}">>]).


within_limit_test() ->
    Json = nested_array(8),
    ?assertEqual([[[[[[[[]]]]]]]], dec(Json, [{max_depth, 8}])).


at_limit_object_test() ->
    Json = nested_object(4),
    ?assertMatch({[{<<"a">>, _}]}, dec(Json, [{max_depth, 4}])).


exceeds_limit_array_test() ->
    Json = nested_array(9),
    ?assertError({_, max_depth_exceeded}, dec(Json, [{max_depth, 8}])).


exceeds_limit_object_test() ->
    Json = nested_object(5),
    ?assertError({_, max_depth_exceeded}, dec(Json, [{max_depth, 4}])).


mixed_nesting_test() ->
    %% Depth counts both objects and arrays: {"a":[{"a":[]}]} is depth 4.
    Json = <<"{\"a\":[{\"a\":[]}]}">>,
    ?assertMatch({[{<<"a">>, _}]}, dec(Json, [{max_depth, 4}])),
    ?assertError({_, max_depth_exceeded}, dec(Json, [{max_depth, 3}])).


depth_resets_between_siblings_test() ->
    %% Sibling containers don't accumulate depth; each [] is depth 1.
    Json = <<"[[],[],[],[]]">>,
    ?assertEqual([[], [], [], []], dec(Json, [{max_depth, 2}])).


zero_means_unlimited_test() ->
    Json = nested_array(500),
    ?assertEqual(ok, element(1, {ok, dec(Json, [{max_depth, 0}])})).


default_is_unlimited_test() ->
    Json = nested_array(500),
    ?assertEqual(ok, element(1, {ok, dec(Json)})).
