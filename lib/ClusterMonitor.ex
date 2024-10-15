defmodule ClusterMonitor do
  require Logger
  use GenServer

  # Timer configuration
  @fetch_interval Application.compile_env(:cluster_bot, :fetch_interval, 5 * 1000)
  @reconnect_interval Application.compile_env(:cluster_bot, :reconnect_interval, 5 * 1000)
  @refresh_interval Application.compile_env(:cluster_bot, :refresh_interval, 60 * 1000)

  # Cachex configuration
  @output Application.compile_env(:cluster_bot, :output, "clusterbot.cache")
  @cache Application.compile_env(:cluster_bot, :cache, :cluster_bot)

  @moduledoc """
  ClusterMonitor is a GenServer implementation that performs three tasks:

  - collect nodes and keep them in the state and cache (with expiration)
  - reconnect to nodes that are no longer connected
  - refresh cache for connected nodes

  All features are mandatory and cannot be disabled.
  The only option one whould have, is increasing the interval timers to such a hight amount, that an exection is impossible.
  """

  def start_link(opts \\ []) do
    Cachex.start_link(@cache)
    Cachex.restore(@cache, @output)

    GenServer.start_link(__MODULE__, get_nodes(), opts)
  end

  def init(state) do
    :timer.send_interval(@fetch_interval, :collect)
    :timer.send_interval(@reconnect_interval, :reconnect)
    :timer.send_interval(@refresh_interval, :refresh)

    {:ok, state}
  end

  def handle_info(:collect, state) do
    new_nodes =
      Node.list()
      |> Enum.filter(fn node -> !Enum.member?(state, node) end)

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

    {:noreply, state ++ new_nodes}
  end

  def handle_info(:reconnect, state) do
    missing_nodes =
      state
      |> Enum.filter(fn node -> !Enum.member?(Node.list(), node) end)

    # Check if any nodes are missing (disconnected)
    if length(missing_nodes) > 0 do
      Logger.info(~s(Nodes missing: #{inspect(missing_nodes)}... Reconnecting))
    end

    # Filter known nodes for nodes that are disconnected and try to reconnect
    get_nodes()
    |> Enum.filter(fn node -> !Enum.member?(Node.list(), node) end)
    |> Enum.each(fn node ->
      Logger.debug(~s(Connecting to node: #{inspect(node)}))

      Node.connect(node)
    end)

    {:noreply, Node.list()}
  end

  def handle_info(:refresh, state) do
    Node.list()
    |> Enum.each(fn node ->
      Cachex.refresh(@cache, "#{node}")
    end)

    {:noreply, state}
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
