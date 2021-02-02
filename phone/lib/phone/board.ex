defmodule Phone.Board do
  @moduledoc """
    Initialize modem board and UART
  """
  use GenServer

  alias Phone.Phone
  alias Circuits.UART
  alias Circuits.GPIO

  require Logger

  # Startup

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :board)

  # Callbacks

  defstruct [:uart_pid, :gpio_ref, :phone_pid]

  @impl GenServer
  @spec init(any) :: {:ok, %{gpio_ref: -1, phone_pid: -1, uart_pid: -1}, {:continue, :start}}
  def init(_state) do
    Process.flag(:trap_exit, true)
    {:ok, %{uart_pid: -1, gpio_ref: -1, phone_pid: -1}, {:continue, :start}}
  end

  @impl GenServer
  def terminate(reason, %{gpio_ref: gpio} = _state) do
    Logger.info("***Board: terminating: #{inspect(self())}: #{inspect(reason)}")
    toggle_power(gpio)
    :ok
  end

  # GenServer callbacks
  @impl GenServer
  def handle_continue(:start, state) do
    {uart, gpio} = start("ttyAMA0")
    Logger.info("***Board started uart_pid: #{inspect(uart)} gpio_ref: #{inspect(gpio)}")
    {:noreply, %{state | uart_pid: uart, gpio_ref: gpio, phone_pid: -1}}
  end

  @impl GenServer
  def handle_cast(:listener_started, %{uart_pid: uart} = state) do
    Logger.info("***Board listener: #{inspect(Process.whereis(:listener))}")
    UART.controlling_process(uart, Process.whereis(:listener))
    :timer.sleep(200)
    GenServer.cast(self(), :start_board)
    Nerves.Runtime.validate_firmware()
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start, state) do
    Logger.info("***Board start PID: #{inspect(self())}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start_board, %{uart_pid: uart, phone_pid: phone} = state) when phone == -1 do
    {:noreply, %{state | phone_pid: Phone.start(uart)}}
  end

  @impl GenServer
  def handle_cast(:start_board, state) do
    Logger.info("***Board start_board already started")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop_board, state) do
    Phone.stop()
    {:noreply, %{state | phone_pid: -1}}
  end

  # private functions
  defp start(tty) do
    {:ok, gpio} = GPIO.open(4, :output)
    Logger.debug("***start, gpio_ref: #{inspect(gpio)}")
    Logger.debug("***start, Toggle Power")
    toggle_power(gpio)
    :timer.sleep(1500)
    toggle_power(gpio)
    # Pause to let modem reset before we query it
    :timer.sleep(2000)

    {:ok, uart_pid} = UART.start_link()
    Logger.debug("***start, uart_pid: #{inspect(uart_pid)}")

    :ok =
      UART.open(
        uart_pid,
        tty,
        speed: 115_200,
        active: true,
        framing: {UART.Framing.Line, separator: "\r\n"},
        id: :pid
      )

    Logger.debug("***UART open")
    {uart_pid, gpio}
  end

  defp toggle_power(gpio) do
    :ok = GPIO.write(gpio, 0)
    :timer.sleep(200)
    :ok = GPIO.write(gpio, 1)
    :timer.sleep(200)
    :ok = GPIO.write(gpio, 0)
  end
end
