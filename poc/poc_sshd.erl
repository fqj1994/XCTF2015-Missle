#!/usr/bin/env escript

customShell(MissleId, Parent) ->
    Parent ! "connected",
    {ok, ["launch-missle", Target]} = io:fread("Welcome to Missle " ++ integer_to_list(MissleId) ++ "\n", "~s ~s"),
    Parent ! Target,
    io:format("~s~n", ["Successfully destroyed target " ++ Target ++ "$(DISPLAY=:0 notify-send asdf)"]).

loop() ->
    receive
        Data ->
            io:format("~p~n", [Data])
    end,
    loop().


main(_) ->
    ssh:start(),

    Pid = self(),

    Ret = ssh:daemon(any, 9999, [{system_dir, "/tmp/ssh_daemon"},
                           {pwdfun, fun(_, _) -> true end},
                           {shell, fun(_) -> spawn(fun() -> customShell(45, Pid) end) end}
                          ]),
    io:format("~p~n", [Ret]),

    loop().
