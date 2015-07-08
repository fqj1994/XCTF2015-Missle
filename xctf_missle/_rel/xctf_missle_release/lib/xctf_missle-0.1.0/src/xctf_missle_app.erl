-module(xctf_missle_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
	xctf_missle_sup:start_link().

stop(_State) ->
	ok.
