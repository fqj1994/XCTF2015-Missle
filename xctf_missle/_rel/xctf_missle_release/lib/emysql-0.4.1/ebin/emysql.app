%% Settings (defaults in include/emysql.hrl):
%% default_timeout (TIMEOUT = 8000)
%% lock_timeout (LOCK_TIMEOUT = 5000)

{application, emysql, [
    {description, "Emysql - Erlang MySQL driver"},
    {vsn, "0.4.1"},
    {modules, [emysql_app, emysql_auth, emysql_conn, emysql_conn_mgr, emysql_conv, emysql, emysql_statements, emysql_sup, emysql_tcp, emysql_util, emysql_worker]}, 
    {mod, {emysql_app, ["Fri Jul 10 19:10:33 CST 2015"]}},
    {registered, [emysql_conn_mgr, emysql_sup]},
    {applications, [kernel, stdlib, crypto]},
    {env, [
      {default_timeout, 5000},
      {conn_test_period, 28000}]}
]}.
