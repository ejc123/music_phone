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
  @spec init(any) :: {:ok, {-1}}
  def init(_state) do
    Logger.debug("***Phone: init PID: #{inspect(self())}")
    {:ok, {-1}}
  end

  @impl GenServer
  def handle_call(:get_uart, pid, {uart_pid} = state) do
    Logger.debug("***Phone: get_uart from #{inspect(pid)}")
    {:reply, uart_pid, state}
  end

  @impl GenServer
  def handle_cast(:answer, {uart_pid} = state) do
    Logger.debug("***Phone :answer")
    GenServer.cast(:audio, :start_audio)
    :timer.sleep(200)
    UART.write(uart_pid, "ATA")
    :timer.sleep(500)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:hangup, {uart_pid} = state) do
    Logger.debug("***Phone :hangup")
    UART.write(uart_pid, "ATH")
    :timer.sleep(200)
    GenServer.cast(:audio, :stop_audio)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:start, uart_pid}, _state) do
    Logger.debug("***Phone :start")
    UART.write(uart_pid, "ATZ")
    :timer.sleep(200)
    ## Set up calling line presentation (caller id)
    UART.write(uart_pid, "AT+CLIP=1")
    :timer.sleep(200)
    {:noreply, {uart_pid}}
  end

  @impl GenServer
  def handle_cast(:stop, {uart_pid} = _state) do
    Logger.debug("***Phone :stop")
    UART.write(uart_pid, "ATZ")
    :timer.sleep(200)
    UART.write(uart_pid, "AT+CLIP=0")
    :timer.sleep(200)
    {:noreply, {uart_pid}}
  end
  @impl GenServer
  def handle_info(message, state) do
    Logger.info("Other message #{inspect(message)}")
    {:noreply, state}
  end
end
