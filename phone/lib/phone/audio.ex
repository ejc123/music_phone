defmodule Phone.Audio do
  use GenServer

  @moduledoc """
    Set up and use the Audio feature
  """
  require Logger

  @path "/srv/erlang/lib/phone-0.1.0/priv"

  # Startup

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: start_link([])
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :audio)

  # Public interface

  @spec start() :: pid
  def start() do
    Logger.debug("***Audio: start self PID: #{inspect(self())}")
    GenServer.cast(:audio, :start)
    self()
  end

  @spec stop :: :ok
  def stop() do
    GenServer.cast(:audio, :stop)
  end

  # Server

  @impl GenServer
  @spec init(any) :: {:ok, {-1}}
  def init(_state) do
    Logger.debug("***Audio init PID: #{inspect(self())}")
    {:ok, {-1}}
  end

  @impl GenServer
  def handle_cast(:start_audio, {player} = _state) do
    Logger.debug("***Audio :start_audio")

    {output, status} = System.cmd("#{@path}/stop.sh", [])
    Logger.debug("***Audio :stopping output: #{inspect(output)}, status: #{inspect(status)}")

    #case player != -1 && Process.alive?(player) do
    #  true ->
    #    Process.exit(player, :kill)
#
#      _ ->
#        false
#    end

    {:ok, player_pid} =
      Task.start(fn ->
        {output, status} = System.cmd("#{@path}/start.sh", ["#{@path}/test.wav"])
        Logger.debug("***Task :played output: #{inspect(output)}, status: #{inspect(status)}")

        GenServer.cast(:phone, :hangup)
      end)

    {:noreply, {player_pid}}
  end

  @impl GenServer
  def handle_cast(:stop_audio, {player_pid} = _state) do
    Logger.debug("***Audio :stop_audio2")

    {output, status} = System.cmd("#{@path}/stop.sh", [])
    Logger.debug("***Audio :stop_audio2 output: #{inspect(output)}, status: #{inspect(status)}")

#    case player_pid != -1 && Process.alive?(player_pid) do
#      true ->
#        Process.exit(player_pid, :kill)
#
#      _ ->
#        false
#    end

    {:noreply, {-1}}
  end

  @impl GenServer
  def handle_cast(:start, _state) do
    Logger.debug("***Audio :start")
    GenServer.cast(:audio, :stop_audio)
    {:noreply, {-1}}
  end

  @impl GenServer
  def handle_cast(:stop, _state) do
    Logger.debug("***Audio :stop")
    GenServer.cast(self(), :stop_audio)
    {:noreply, {-1}}
  end

  @impl GenServer
  def handle_info(:stop_audio, state) do
    Logger.info("***Audio INFO :stop_audio")
    GenServer.cast(:audio, :stop_audio)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("Other message #{inspect(message)}")
    {:noreply, state}
  end
end
