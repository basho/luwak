-module(test_helper).

-export([riak_test/1]).

riak_test(Fun) ->
  start_riak(),
  {ok, Riak} = riak:local_client(),
  Ret = (catch Fun(Riak)),
  stop_riak(),
  case Ret of
    {'EXIT', Err} -> throw(Err);
    _ -> Ret
  end.

start_riak() ->
    [] = os:cmd("epmd -daemon"),
    case net_kernel:start([test_luwak, shortnames]) of
        {ok,_} -> ok;
        {error,{already_started,_}} -> ok
    end,
%    error_logger:delete_report_handler(error_logger_tty_h),%%SLF:
    application:start(sasl),
%    error_logger:delete_report_handler(sasl_report_tty_h),%%SLF:
    Apps = [crypto, os_mon, runtime_tools, mochiweb, webmachine, riak_sysmon,
            riak_core, luke, erlang_js, skerl, bitcask, riak_kv],
    [begin
         application:stop(A),
         [application:unset_env(A, Key) ||
             {Key, _} <- application:get_all_env(A)],
         FName = atom_to_list(A) ++ ".app",
         FullName = code:where_is_file(FName),
         {ok, [{_, _, Ps}]} = file:consult(FullName),
         Es = proplists:get_value(env, Ps, []),
         [application:set_env(A, K, V) || {K, V} <- Es]
     end || A <- Apps],
    %% Started independently by other eunit tests
    [catch exit(whereis(Name), kill) ||
        Name <- [riak_core_ring_manager, riak_kv_vnode_master]],
    timer:sleep(100),

    % Dir = "/tmp/ring-" ++ os:getpid(),
    % filelib:ensure_dir(Dir ++ "/"),
    % application:set_env(riak_core, ring_state_dir, Dir),
    application:set_env(riak_kv, storage_backend, riak_kv_ets_backend),
    
io:format(user, "SLF temp: ~w\n", [lists:sort(registered())]),
[io:format(user, "SLF temp: ~p ~p\n", [A, application:get_all_env(A)]) || A <- Apps],
    load_and_start_apps(Apps),
    timer:sleep(150).
    
stop_riak() ->
  application:stop(riak_kv).
  
load_and_start_apps([]) -> ok;
load_and_start_apps([App|Tail]) ->
  ensure_loaded(App),
  ensure_started(App),
  load_and_start_apps(Tail).

ensure_loaded(App) ->
  case application:load(App) of
      ok ->
          ok;
      {error,{already_loaded,App}} ->
          ok;
      Error ->
          throw({"failed to load", App, Error})
  end.

ensure_started(App) ->
  case application:start(App) of
      ok ->
          ok;
      {error,{already_started,App}} ->
          ok;
      Error ->
          throw({"failed to start", App, Error})
  end.
