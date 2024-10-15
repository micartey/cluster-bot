defmodule ClusterMonitor do
  require Logger
  use GenServer

  @interval 5 * 1000
  @refresh_interval 60 * 1000

  @cache "clusterbot.cache"

  def start_link(opts \\ []) do
    Cachex.start_link(:cluster_monitor)
    Cachex.restore(:cluster_monitor, @cache)

    GenServer.start_link(__MODULE__, get_nodes(), opts)
  end

  def init(state) do
    :timer.send_interval(@interval, :collect)
    :timer.send_interval(@interval, :recreate)
    :timer.send_interval(@refresh_interval, :refresh)

    {:ok, state}
  end

  def handle_info(:collect, state) do
    new_nodes =
      Node.list()
      |> Enum.filter(fn node -> !Enum.member?(state, node) end)

    if length(new_nodes) > 0 do
      Logger.debug(~s(New nodes connected: #{inspect(new_nodes)}))

      # Store new nodes to cache
      new_nodes
      |> Enum.each(fn node ->
        Cachex.put(:cluster_monitor, "#{node}", node)
        Cachex.expire(:cluster_monitor, "#{node}", :timer.hours(24))
      end)

      Cachex.save(:cluster_monitor, @cache)
    end

    {:noreply, state ++ new_nodes}
  end

  def handle_info(:recreate, state) do
    missing_nodes =
      state
      |> Enum.filter(fn node -> !Enum.member?(Node.list(), node) end)

    # Check if any known nodes are missing
    if length(missing_nodes) > 0 do
        Logger.debug(~s(Nodes missing: #{inspect(missing_nodes)}))

      # Reconnect to nodes
      missing_nodes
      |> Enum.each(fn node ->
        Logger.info(~s(Connecting to node: #{inspect(node)}))

        Node.connect(node)
      end)
    end

    {:noreply, state}
  end

  def handle_info(:refresh, state) do
    Node.list()
    |> Enum.each(fn node ->
        Cachex.refresh(:cluster_monitor, "#{node}")
    end)

    {:noreply, state}
  end

  def handle_call(:get_nodes, _caller_pid, state) do
    {:reply, state, state}
  end

  defp get_nodes() do
    {:ok, keys} = Cachex.keys(:cluster_monitor)

    keys
    |> Enum.map(fn key ->
      {:ok, value} = Cachex.get(:cluster_monitor, key)
      value
    end)
  end
end
