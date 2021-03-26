defmodule Phone.Audio do
  @moduledoc """
    Set up and use the Audio feature
  """
  use GenServer

  require Logger

  @version Mix.Project.config[:version]
  @path "/srv/erlang/lib/phone-#{@version}/priv"

  # Startup

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: start_link([])
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :audio)

  # Public interface

  @spec start() :: pid
  def start() do
    Logger.info("***Audio: start PID: #{inspect(self())}")
    GenServer.cast(:audio, :start)
    self()
  end

  @spec stop :: :ok
  def stop() do
    GenServer.cast(:audio, :stop)
  end

  # Callbacks

  defstruct [:player_pid]

  @impl GenServer
  @spec init(any) :: {:ok, %{player_pid: -1}}
  def init(_state) do
    {:ok, %{player_pid: -1}}
  end

  @impl GenServer
  def handle_cast({:start_audio, file}, state) do
    Logger.debug("***Audio :start_audio file: #{inspect(file)}")
    {output, status} = System.cmd("#{@path}/stop.sh", [])
    Logger.debug("***Audio :stopping output: #{inspect(output)}, status: #{inspect(status)}")

    {:ok, player_pid} =
      Task.start(fn ->
        {output, status} = System.cmd("#{@path}/start.sh", ["#{@path}/#{file}"])
        Logger.debug("***Task :played output: #{inspect(output)}, status: #{inspect(status)}")

        GenServer.cast(:phone, :hangup)
      end)

    {:noreply, %{state | player_pid: player_pid}}
  end

  @impl GenServer
  def handle_cast(:stop_audio, state) do
    Logger.debug("***Audio :stop_audio")
    {output, status} = System.cmd("#{@path}/stop.sh", [])
    Logger.debug("***Audio :stop_audio output: #{inspect(output)}, status: #{inspect(status)}")
    {:noreply, %{state | player_pid: -1}}
  end

  @impl GenServer
  def handle_cast(:start, state) do
    Logger.debug("***Audio :start")
    GenServer.cast(:audio, :stop_audio)
    {:noreply, %{state | player_pid: -1}}
  end

  @impl GenServer
  def handle_cast(:stop, state) do
    Logger.debug("***Audio :stop")
    GenServer.cast(self(), :stop_audio)
    {:noreply, %{state | player_pid: -1}}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("***Audio other message #{inspect(message)}")
    {:noreply, state}
  end
end
