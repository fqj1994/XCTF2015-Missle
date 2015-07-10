{application, xctf_missle, [
	{description, ""},
	{vsn, "0.1.0"},
	{id, "6e7cd3c-dirty"},
	{modules, ['conf','txt_log','ws_missle','xctf_missle_app','xctf_missle_sup']},
	{registered, []},
	{applications, [
		kernel,
		stdlib,
        cowboy,
        emysql,
        jsonerl,
        crypto,
        ssh
	]},
	{mod, {xctf_missle_app, []}},
	{env, []}
]}.
