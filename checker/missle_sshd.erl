#!/usr/bin/env escript

customShell(MissleId, Parent, Rnd) ->
    {ok, ["launch-missle", Target]} = io:fread("Welcome to Missle " ++ MissleId ++ "\n", "~s ~s"),
    io:format("~s~n", ["Successfully destroyed target " ++ Target ++ "-" ++ Rnd]),
    Parent ! done.



hexstring(Binary) when is_binary(Binary) ->
    list_to_binary(lists:flatten(lists:map(
                                   fun(X) -> io_lib:format("~2.16.0b", [X]) end, 
                                   binary_to_list(Binary)))).


sha1(Input) ->
    hexstring(crypto:hash(sha, Input)).


main([Flag]) ->
    crypto:start(),
    ssh:start(),
    Rnd = binary_to_list(base64:encode(crypto:strong_rand_bytes(10))),
    Rnd2 = binary_to_list(base64:encode(crypto:strong_rand_bytes(10))),
    Pid = self(),
    HashedFlag = binary_to_list(sha1(sha1(Flag))),
    timer:send_after(5000, timeout),

    _Ret = ssh:daemon(any, 9999, [{system_dir, "/tmp/ssh_daemon"},
                                 {pwdfun, fun("root", Password) when Password =:= HashedFlag -> true; (_, _) -> Pid ! wrongflag, false end},
                                 {shell, fun(_) -> spawn(fun() -> customShell(Rnd2, Pid, Rnd) end) end}
                          ]),
    io:format("ready~n"),

    receive
        wrongflag ->
            io:format("Flag is not correct.~n", []);
        {wserror, _} ->
            io:format("Failed to uprade to Websocket.~n", []);
        done ->
            io:format("ok~n~s~n~s~n", [Rnd, Rnd2]);
        timeout ->
            io:format("No connection received from missle.~n", [])
    end,

    ssh:stop_daemon(any, 9999).
