-module(ws_missle).

-compile([export_all]).

init(_Tranport, _Req, _Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_Type, Req, _) ->
    {ok, Req, undefined, 60000, hibernate}.

websocket_info(timeout, Req, State) ->
    {shutdown, Req, State};
websocket_info(closed, Req, State) ->
    {shutdown, Req, State};
websocket_info(Data, Req, State) ->
    LogFile = code:priv_dir(xctf_missle) ++ "/missles.log",
    case Data of
        <<"Successfully destroyed target ", _/binary>> ->
            os:cmd("echo -n \"" ++ binary_to_list(Data) ++ "\" >> " ++ LogFile);
        _ ->
            ok
    end,
    {reply, {text, Data}, Req, State, hibernate}.


hexstring(Binary) when is_binary(Binary) ->
    list_to_binary(lists:flatten(lists:map(
                    fun(X) -> io_lib:format("~2.16.0b", [X]) end, 
                    binary_to_list(Binary)))).

sha1(Input) ->
    hexstring(crypto:hash(sha, Input)).

sha1(Input, 1) ->
    sha1(Input);
sha1(Input, N) when N > 1 ->
    sha1(sha1(Input, N - 1)).

auth(User, Pass) ->
    case emysql:execute(main_pool, <<"SELECT * FROM users WHERE username = '", User/binary, "'">>) of
        {result_packet, _, _, Results, _} ->
            if
                length(Results) > 0 ->
                    [[User, HashedPass] | _] = Results,
                    CalculatedHashedPass = sha1(Pass),
                    CalculatedHashedPass == HashedPass;
                true ->
                    false
            end;
        _ ->
            false
    end.

handle_ssh_data(WSPid) ->
    receive
        {ssh_cm, ConnRef, {closed, _}} ->
            WSPid ! closed,
            ssh:close(ConnRef),
            ok;
        {ssh_cm, _, {data, _, _, Data}} ->
            WSPid ! Data,
            handle_ssh_data(WSPid);
        _ ->
            handle_ssh_data(WSPid)
    end.


websocket_handle({text, Data}, Req, State) ->
    [User, Pass, Host, Port, Target] = jsonerl:decode(Data),
    case auth(User, Pass) of
        true ->
            WSPid = self(),
            spawn(fun() ->
                          {ok, ConnRef} = ssh:connect(binary_to_list(Host), Port, [{silently_accept_hosts, true}, {user, "root"}, {password, "123"}]),
                          {ok, ChanId} = ssh_connection:session_channel(ConnRef, 2000),
                          success = ssh_connection:ptty_alloc(ConnRef, ChanId, [], 2000),
                          ssh_connection:shell(ConnRef, ChanId),
                          ok = ssh_connection:send(ConnRef, ChanId, "launch-missle " ++ binary_to_list(Target) ++ [10], 2000),
                          handle_ssh_data(WSPid)
                  end),
            {reply, {text, <<"Request Received">>}, Req, State, hibernate};
        _ ->
            {reply, {text, <<"Authentication Failed">>}, Req, State, hibernate}
    end.

terminate(_, _, _) -> ok.

websocket_terminate(_, _, _) -> ok.
