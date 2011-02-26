-module(luwak_checksum_tests).

-include_lib("eunit/include/eunit.hrl").

one_off_checksum_test() ->
  test_helper:riak_test(fun(Riak) ->
io:format(user, "Line ~p ~p ~p\n", [?MODULE, ?LINE, time()]),
      Sha = crypto:sha(<<"chilled monkey brains">>),
io:format(user, "Line ~p ~p ~p\n", [?MODULE, ?LINE, time()]),
      {ok, File} = luwak_file:create(Riak, <<"file1">>, [{tree_order,2},{block_size,2}], dict:new()),
io:format(user, "Line ~p ~p ~p\n", [?MODULE, ?LINE, time()]),
      {ok, _, File1} = luwak_io:put_range(Riak, File, 0, <<"chilled monkey brains">>),
io:format(user, "Line ~p ~p ~p\n", [?MODULE, ?LINE, time()]),
      timer:sleep(100),
      Checksum = luwak_checksum:sha1(Riak, File1),
io:format(user, "Line ~p ~p ~p\n", [?MODULE, ?LINE, time()]),
      ?assertEqual(Sha, Checksum)
    end).

do_a_simple_checksum_test() ->
  test_helper:riak_test(fun(Riak) ->
      Sha = crypto:sha(<<"chilled monkey brains">>),
      {ok, File} = luwak_file:create(Riak, <<"file1">>, [{checksumming,true}], dict:new()),
      {ok, _, File1} = luwak_io:put_range(Riak, File, 0, <<"chilled monkey brains">>),
      ?assertEqual({sha1,Sha}, luwak_file:get_property(File1,checksum))
    end).
