defmodule ClusterMonitor do
  require Logger
  use GenServer

  defstruct nodes: [], lifetime: 0

  # Timer configuration
  @fetch_interval Application.compile_env(:cluster_bot, :fetch_interval, 5 * 1000)
  @reconnect_interval Application.compile_env(:cluster_bot, :reconnect_interval, 5 * 1000)
  @refresh_interval Application.compile_env(:cluster_bot, :refresh_interval, 60 * 1000)

  # Cachex configuration
  @output Application.compile_env(:cluster_bot, :output, ".clusterbot.cache")
  @cache Application.compile_env(:cluster_bot, :cache, :cluster_bot)

  @moduledoc """
  ClusterMonitor is a GenServer implementation that performs three tasks:

  - collect nodes and keep them in the state and cache (with expiration)
  - reconnect to nodes that are no longer connected
  - refresh cache for connected nodes

  All features are mandatory and cannot be disabled.
  The only option one whould have, is increasing the interval timers to such an amount, that an exection is impossible.
  """

  def start_link(opts \\ []) do
    Cachex.start_link(@cache)
    Cachex.restore(@cache, @output)

    GenServer.start_link(__MODULE__, nil, name: :cluster_monitor)
  end

  def init(_) do
    :timer.send_interval(@fetch_interval, :collect)
    :timer.send_interval(@reconnect_interval, :reconnect)
    :timer.send_interval(@refresh_interval, :refresh)

    {:ok,
      %ClusterMonitor{
        nodes: get_nodes(),
        lifetime: :os.system_time(:millisecond)
      }
    }
  end

  def handle_info(:collect, %ClusterMonitor{nodes: nodes} = state) do
    new_nodes =
      Node.list()
      |> Enum.filter(fn node -> !Enum.member?(nodes, node) end)

    if length(new_nodes) > 0 do
      Logger.info(~s(New nodes connected: #{inspect(new_nodes)}))

      # Store new nodes to cache
      new_nodes
      |> Enum.each(fn node ->
        Cachex.put(@cache, "#{node}", node)
        Cachex.expire(@cache, "#{node}", :timer.hours(24))
      end)

      Cachex.save(@cache, @output)
    end

    {:noreply, %ClusterMonitor{state | nodes: nodes ++ new_nodes}}
  end

  def handle_info(:reconnect, %ClusterMonitor{nodes: nodes} = state) do
    missing_nodes =
      nodes
      |> Enum.filter(fn node -> !Enum.member?(Node.list(), node) end)

    # Check if any nodes are missing (disconnected)
    if length(missing_nodes) > 0 do
      Logger.notice(~s(Nodes disconnected: #{inspect(missing_nodes)}))
    end

    # Filter known nodes for nodes that are disconnected and try to reconnect
    get_nodes()
    |> Enum.filter(fn node -> !Enum.member?(Node.list(), node) end)
    |> Enum.each(fn node ->
      Logger.debug(~s(Connecting to node: #{inspect(node)}))

      Node.connect(node)
    end)

    {:noreply, %ClusterMonitor{state | nodes: Node.list()}}
  end

  def handle_info(:refresh, %ClusterMonitor{} = state) do
    Node.list()
    |> Enum.each(fn node ->
      Cachex.refresh(@cache, "#{node}")
    end)

    {:noreply, state}
  end

  def handle_call(:lifetime, _caller_pid, %ClusterMonitor{lifetime: lifetime} = state) do
    {:reply, lifetime, state}
  end

  # {_, pid} = ClusterMonitor.start_link()
  # GenServer.call(pid, :oldest_node)
  def handle_call(:oldest_node, _caller_pid, %ClusterMonitor{lifetime: lifetime} = state) do
    {node, node_lifetime} = Node.list()
    |> Stream.map(fn node ->
      pid = :rpc.call(node, Process, :whereis, [:cluster_monitor])
      lifetime = :rpc.call(node, GenServer, :call, [pid, :lifetime])

      {node, lifetime}
    end)
    |> Enum.sort_by(fn {_node, lifetime} -> lifetime end)
    |> List.first()

    if node && lifetime < node_lifetime do
      {:reply, node(), state}
    else
      {:reply, node, state}
    end
  end

  defp get_nodes() do
    {:ok, keys} = Cachex.keys(@cache)

    keys
    |> Enum.map(fn key ->
      {:ok, value} = Cachex.get(@cache, key)
      value
    end)
  end
end
