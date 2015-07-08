-module(xctf_missle_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	Procs = [],
    emysql:add_pool(main_pool, [{size, 50}, {user, conf:dbuser()}, {password, conf:dbpass()}, {database, "missles"}, {encoding, utf8}]),
    URLDispatch = cowboy_router:compile([{'_', [ {[<<"/">>], cowboy_static, {priv_file, xctf_missle, "static/index.html"}},
                                                 {[<<"/missle">>], ws_missle, []},
                                                 {[<<"/log">>], txt_log, []}
                                               ]}]),
    cowboy:start_http(missleserv, 100, [{max_connections, 1024}, {port, 20001}], [{env, [{dispatch, URLDispatch}]}]),
	{ok, {{one_for_one, 1, 5}, Procs}}.
