defmodule Phone.Phone do
  @moduledoc """
    Set up and use phone
  """
  use GenServer

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
    Logger.info("***Phone: start PID: #{inspect(self())}")
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

  # Callbacks

  defstruct [:uart_pid]

  @impl GenServer
  @spec init(any) :: {:ok, %{uart_pid: -1}}
  def init(_state) do
    {:ok, %{uart_pid: -1}}
  end

  @impl GenServer
  def handle_call(:get_uart, pid, %{uart_pid: upid} = state) do
    Logger.debug("***Phone: get_uart from #{inspect(pid)}")
    {:reply, upid, state}
  end

  @impl GenServer
  def handle_cast({:answer, file}, %{uart_pid: upid} = state) do
    Logger.debug("***Phone :answer file: #{inspect(file)}")
    GenServer.cast(:audio, {:start_audio, file})
    :timer.sleep(200)
    UART.write(upid, "ATA")
    :timer.sleep(500)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:hangup, %{uart_pid: upid} = state) do
    Logger.debug("***Phone :hangup")
    UART.write(upid, "ATH")
    :timer.sleep(200)
    GenServer.cast(:audio, :stop_audio)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:start, uart_pid}, state) do
    Logger.debug("***Phone :start")
    reset(uart_pid)
    ## Set up calling line presentation (caller id)
    UART.write(uart_pid, "AT+CLIP=1")
    :timer.sleep(200)
    {:noreply, %{state | uart_pid: uart_pid}}
  end

  @impl GenServer
  def handle_cast(:stop, %{uart_pid: upid} = state) do
    Logger.debug("***Phone :stop")
    reset(upid)
    UART.write(upid, "AT+CLIP=0")
    :timer.sleep(200)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("***Phone other message #{inspect(message)}")
    {:noreply, state}
  end

  defp reset(pid) do
    :timer.sleep(200)
    UART.write(pid, "ATZ")
    :timer.sleep(200)
  end
end
