# Cluster-Bot

<div align="center">
  <a href="https://elixir-lang.org/">
    <img
      src="https://img.shields.io/badge/Written%20in-elixir-%237C6D91?style=for-the-badge"
      height="30"
    />
  </a>
  <a href="https://hex.pm/packages/cluster_bot">
    <img
      src="https://img.shields.io/badge/hex.pm-cluster_bot-%23333333?style=for-the-badge"
      height="30"
    />
  </a>
</div>

<br>

<p align="center">
  <a href="#introduction">Introduction</a> •
  <a href="#installation">Installation</a> •
  <a href="#getting-started">Getting Started</a>
</p>

## Introduction

`ClusterBot` is a small elixir library to manage nodes and automatically reconnect if a node disconnects thus trying to maintain a constant pool of nodes.
Nodes are cached using [Cachex](https://hexdocs.pm/cachex/Cachex.html) and stored to the file system.
If a node is not reachable in 24 hours, it will permamently be removed from the cache.

## Installation

<!-- https://hex.pm/docs/publish -->

Add `cluster_bot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cluster_bot, "~> 0.1.0"}
  ]
end
```

## Getting Started

The [ClusterMonitor](https://hexdocs.pm/cluster_bot/doc/ClusterMonitor.html) implements the GenServer behavior and is thus usable with a standard OTP supervision tree.

```ex
children = [
  ClusterMonitor,
  ...
]

Supervisor.start_link(children, [
  strategy: :one_for_one,
  name: Your.Supervisor
])
```

You are also able to change some parameters in you config.
This is purly optional and mainly involves interval times:

```ex
config :cluster_bot,
  fetch_interval: 5_000,
  reconnect_interval: 5_000, 
  refresh_interval: 60_000,
  output: "cache.bin",
```

The library is meant to be passively used thus doesn't need to be interacted with.