searchData={"content_type":"text/markdown","items":[{"doc":"ClusterMonitor is a GenServer implementation that performs three tasks:\n\n- collect nodes and keep them in the state and cache (with expiration)\n- reconnect to nodes that are no longer connected\n- refresh cache for connected nodes\n\nAll features are mandatory and cannot be disabled.\nThe only option one whould have, is increasing the interval timers to such a hight amount, that an exection is impossible.","ref":"ClusterMonitor.html","title":"ClusterMonitor","type":"module"},{"doc":"Returns a specification to start this module under a supervisor.\n\nSee `Supervisor`.","ref":"ClusterMonitor.html#child_spec/1","title":"ClusterMonitor.child_spec/1","type":"function"},{"doc":"","ref":"ClusterMonitor.html#init/1","title":"ClusterMonitor.init/1","type":"function"},{"doc":"","ref":"ClusterMonitor.html#start_link/1","title":"ClusterMonitor.start_link/1","type":"function"},{"doc":"# Cluster-Bot\n\n \n   \n     \n   \n   \n     \n   \n \n\n \n\n \n   Introduction  •\n   Installation  •\n   Getting Started","ref":"readme.html","title":"Cluster-Bot","type":"extras"},{"doc":"`ClusterBot` is a small elixir library to manage nodes and automatically reconnect if a node disconnects thus trying to maintain a constant pool of nodes.\nNodes are cached using [Cachex](https://hexdocs.pm/cachex/Cachex.html) and stored to the file system.\nIf a node is not reachable in 24 hours, it will permamently be removed from the cache.","ref":"readme.html#introduction","title":"Introduction - Cluster-Bot","type":"extras"},{"doc":"<!-- https://hex.pm/docs/publish -->\n\nAdd `cluster_bot` to your list of dependencies in `mix.exs`:\n\n```elixir\ndef deps do\n  [\n    {:cluster_bot, \"~> 0.1.0\"}\n  ]\nend\n```","ref":"readme.html#installation","title":"Installation - Cluster-Bot","type":"extras"},{"doc":"The [ClusterMonitor](https://hexdocs.pm/cluster_bot/doc/ClusterMonitor.html) implements the GenServer behavior and is thus usable with a standard OTP supervision tree.\n\n```ex\nchildren = [\n  ClusterMonitor,\n  ...\n]\n\nSupervisor.start_link(children, [\n  strategy: :one_for_one,\n  name: Your.Supervisor\n])\n```\n\nYou are also able to change some parameters in you config.\nThis is purly optional and mainly involves interval times:\n\n```ex\nconfig :cluster_bot,\n  fetch_interval: 5_000,\n  reconnect_interval: 5_000, \n  refresh_interval: 60_000,\n  output: \"cache.bin\",\n```\n\nThe library is meant to be passively used thus does't need to be interacted with.","ref":"readme.html#getting-started","title":"Getting Started - Cluster-Bot","type":"extras"}],"producer":{"name":"ex_doc","version":[48,46,51,52,46,50]}}