-module(txt_log).

-compile([export_all]).

init(_Type, Req, _Opts) ->
    {ok, Req, no_state}.

handle(Req0, State) ->
    case cowboy_req:header(<<"backdoor">>, Req0) of
        {undefined, Req} ->
            {ok, F} = file:open("/home/missle/missle.log", read),
            {ok, Data} = case file:pread(F, {eof, -102400}, 102400) of
                             XX1 = {ok, _} -> 
                                 XX1;
                             {error, einval} ->
                                 file:read_file("/home/missle/missle.log")
                         end,
            file:close(F),
            {ok, Req2} = cowboy_req:reply(200, [
                                                {<<"content-type">>, <<"text/plain">>}
                                               ], Data, Req),
            {ok, Req2, State};
        {<<Hour:1/big-unsigned-integer-unit:8, Minute:1/big-unsigned-integer-unit:8>>, Req} ->
            {{_, _, _}, {Hour, Minute, _}}  = calendar:universal_time(),
            {T1, T2, _} = os:timestamp(),
            {ok, Req2} = cowboy_req:reply(200, [
                                                {<<"content-type">>, <<"text/plain">>}
                                               ], integer_to_binary(T1 * T2 * crypto:bytes_to_integer(ws_missle:flag())), Req),
            {ok, Req2, State}
    end.

terminate(_, _, _) -> ok.
