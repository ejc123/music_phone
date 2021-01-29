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
    Logger.debug("***Phone: start GPS PID: #{inspect(Phone.GPS)}")
    GenServer.cast(self(), {:start, uart_pid})
    self()
  end

  @spec stop :: :ok
  def stop() do
    GenServer.cast(self(), :stop)
  end

  @spec answer :: :ok
  def answer() do
    GenServer.cast(self(), :answer)
  end

  @spec hangup :: :ok
  def hangup() do
    GenServer.cast(self(), :hangup)
  end

  # Server

  @impl GenServer
  @spec init(any) :: {:ok, {-1, false}}
  def init(_state) do
    Logger.debug("***Phone: init PID: #{inspect(self())}")
    {:ok, {-1, false}}
  end

  @impl GenServer
  def handle_cast(:answer, uart_pid = state) do
    Logger.debug("***Phone :answer")
    UART.write(uart_pid, "ATA")
    :timer.sleep(500)
    {:noreply, state }
  end

  @impl GenServer
  def handle_cast(:hangup, uart_pid = state) do
    Logger.debug("***Phone :hangup")
    UART.write(uart_pid, "ATH")
    :timer.sleep(500)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:play_audio, state) do
    Logger.debug("***Phone :play_audio")
    Toolshed.cmd("aplay -q /srv/erlang/lib/phone-0.1.0/priv/test.wav")
    # GenServer.cast({:global, Fw.Listener},{:play, "/srv/erlang/lib/phone-0.1.0/priv/test.wav"})
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start, uart_pid = state) do
    Logger.debug("***Phone :start")
    ## Set up calling line presentation (caller id)
    UART.write(uart_pid, "AT+CLIP=1")
    :timer.sleep(500)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop, state) do
    Logger.debug("***Phone :stop")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("Other message #{inspect(message)}")
    {:noreply, state}
  end
end