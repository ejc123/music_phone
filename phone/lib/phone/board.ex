defmodule Phone.Board do
  use GenServer

  alias Phone.Phone
  alias Circuits.UART
  alias Circuits.GPIO

  @moduledoc """
    Set up Modem board
  """
  require Logger

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :board)

  @impl GenServer
  @spec init(any) :: {:ok, {0, 0, 0}, {:continue, :start}}
  def init(_state) do
    Process.flag(:trap_exit, true)
    {:ok, {0, 0, 0}, {:continue, :start}}
  end

  @impl GenServer
  def terminate(reason, {_uart_pid, gpio, _phone_pid} = _state) do
    Logger.info("***Board: terminating: #{inspect(self())}: #{inspect(reason)}")
    toggle_power(gpio)
    :ok
  end

  # GenServer callbacks
  @impl GenServer
  @spec handle_continue(:start, any) :: {:noreply, {pid, reference, 0}}
  def handle_continue(:start, _state) do
    tty = "ttyAMA0"

    options = [
      speed: 115_200,
      active: true,
      framing: {UART.Framing.Line, separator: "\r\n"},
      id: :pid
    ]

    {uart_pid, gpio, phone_pid} = start(tty, options)
    {:noreply, {uart_pid, gpio, phone_pid}}
  end

  @impl GenServer
  def handle_cast(:listener_started, {uart_pid, _gpio, _phone_pid} = state) do
    Logger.info("***Board starting listener")
    Logger.info("***Board Listener: #{inspect(Process.whereis(:listener))}")
    UART.controlling_process(uart_pid, Process.whereis(:listener))
    :timer.sleep(200)
    GenServer.cast(self(), :start_board)
    Nerves.Runtime.validate_firmware()
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start, {uart_pid, _gpio, _phone_pid} = state) do
    Logger.info("***Board got start uart_pid: #{inspect(uart_pid)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start_board, {uart_pid, gpio, phone_pid} = _state) when phone_pid == 0 do
    {:noreply, {uart_pid, gpio, Phone.start(uart_pid)}}
  end

  @impl GenServer
  def handle_cast(:start_board, state) do
    Logger.info("***Board start_board already started")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop_board, {uart_pid, gpio, _phone_pid} = _state) do
    Phone.stop()
    {:noreply, {uart_pid, gpio, 0}}
  end

  # private functions
  defp start(_tty, _options) do
    {:ok, gpio} = GPIO.open(4, :output)
    Logger.info("***start, Toggle Power")
    toggle_power(gpio)
    :timer.sleep(1500)
    toggle_power(gpio)
    # Pause to let modem reset before we query it
    :timer.sleep(2000)
    Logger.info("***start, Toggle Power")

    Logger.info("***start, gpio_pid: #{inspect(gpio)}")
    {:ok, uart_pid} = UART.start_link()
    Logger.info("***start, uart_pid: #{inspect(uart_pid)}")

    :ok =
      UART.open(
        uart_pid,
        "ttyAMA0",
        speed: 115_200,
        active: true,
        framing: {UART.Framing.Line, separator: "\r\n"},
        id: :pid
      )

    Logger.debug("***UART open")
    {uart_pid, gpio, 0}
  end

  defp toggle_power(gpio) do
    :ok = GPIO.write(gpio, 0)
    :timer.sleep(200)
    :ok = GPIO.write(gpio, 1)
    :timer.sleep(200)
    :ok = GPIO.write(gpio, 0)
  end
end
