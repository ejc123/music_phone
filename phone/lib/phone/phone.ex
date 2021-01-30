defmodule Phone.Phone do
  use GenServer

  @moduledoc """
    Set up and use the Phone feature
  """
  require Logger
  alias Circuits.UART

  # Startup

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: start_link([])
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :phone)

  # Public interface

  @spec start(any) :: pid
  def start(uart_pid) do
    Logger.debug("***Phone: start self PID: #{inspect(self())}")
    GenServer.cast(:phone, {:start, uart_pid})
    self()
  end

  @spec stop :: :ok
  def stop() do
    GenServer.cast(:phone, :stop)
  end

  @spec answer :: :ok
  def answer() do
    GenServer.cast(:phone, :answer)
  end

  @spec hangup :: :ok
  def hangup() do
    GenServer.cast(:phone, :hangup)
  end

  # Server

  @impl GenServer
  @spec init(any) :: {:ok, {-1, -1}}
  def init(_state) do
    Logger.debug("***Phone: init PID: #{inspect(self())}")
    {:ok, {-1, -1}}
  end

  @impl GenServer
  def handle_call(:get_uart, pid, {uart_pid, _player_pid} = state) do
    Logger.debug("***Phone: get_uart from #{inspect(pid)}")
    {:reply, uart_pid, state}
  end

  @impl GenServer
  def handle_cast(:answer, {uart_pid, _player_pid} = state) do
    Logger.debug("***Phone :answer")
    UART.write(uart_pid, "ATA")
    :timer.sleep(500)
    GenServer.cast(self(), :start_audio)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:hangup, {uart_pid, _player_pid} = state) do
    Logger.debug("***Phone :hangup")
    UART.write(uart_pid, "ATH")
    :timer.sleep(200)
    GenServer.cast(self(), :stop_audio)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start_audio, {uart_pid, player} = _state) do
    Logger.debug("***Phone :start_audio")

    case player != -1 && Process.alive?(player) do
      true ->
        System.cmd("sh", ["-c", " kill `cat /data/aplay.pid`"],
          stderr_to_stdout: true,
          into: IO.stream(:stdio, :line)
        )
        Process.exit(player, :kill)
      _ ->
        false
    end

    {:ok, player_pid} =
      Task.start(fn ->
        Process.send_after(:phone, :hangup, 20000)
        System.cmd("aplay", [
          "-q",
          "-d",
          "20",
          "--process-id-file",
          "/data/aplay.pid",
          "/srv/erlang/lib/phone-0.1.0/priv/test.wav"
        ])
      end)

    {:noreply, {uart_pid, player_pid}}
  end

  @impl GenServer
  def handle_cast(:stop_audio, {uart_pid, player_pid} = _state) do
    Logger.debug("***Phone :stop_audio2")

    case player_pid != -1 && Process.alive?(player_pid) do
      true ->
        System.cmd("sh", ["-c", " kill `cat /data/aplay.pid`"],
          stderr_to_stdout: true,
          into: IO.stream(:stdio, :line)
        )
        Process.exit(player_pid, :kill)
      _ ->
        false
    end

    {:noreply, {uart_pid, -1}}
  end

  @impl GenServer
  def handle_cast({:start, uart_pid}, {_uart_pid, player_pid} = _state) do
    Logger.debug("***Phone :start")
    UART.write(uart_pid, "ATZ")
    :timer.sleep(200)
    ## Set up calling line presentation (caller id)
    UART.write(uart_pid, "AT+CLIP=1")
    :timer.sleep(200)
    {:noreply, {uart_pid, player_pid}}
  end

  @impl GenServer
  def handle_cast(:stop, {uart_pid, player_pid} = _state) do
    Logger.debug("***Phone :stop")
    Process.exit(player_pid, :kill)
    UART.write(uart_pid, "ATZ")
    :timer.sleep(200)
    UART.write(uart_pid, "AT+CLIP=0")
    :timer.sleep(200)
    {:noreply, {uart_pid, player_pid}}
  end

  @impl GenServer
  def handle_info(:stop_audio, state) do
    Logger.info("***Phone INFO :stop_audio")
    GenServer.cast(:phone, :stop_audio)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:hangup, {uart_pid, player} = _state) do
    Logger.info("***Phone INFO :hangup")
    GenServer.cast(:phone, :hangup)
    {:noreply, {uart_pid, player}}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("Other message #{inspect(message)}")
    {:noreply, state}
  end
end
