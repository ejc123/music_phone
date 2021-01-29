defmodule Phone.Board do
  use GenServer

  alias Phone.GPS
  alias Phone.Phone
  alias Circuits.UART
  alias Circuits.GPIO

  @moduledoc """
    Set up Modem/GPS board
  """
  require Logger

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :board)

  @impl GenServer
  @spec init(any) :: {:ok, {0, 0, 0, 0}, {:continue, :start}}
  def init(_state) do
    {:ok, {0, 0, 0, 0}, {:continue, :start}}
  end

  # GenServer callbacks
  @impl GenServer
  def handle_continue(:start, _state) do
    tty = "ttyAMA0"

    options = [
      speed: 115_200,
      active: true,
      framing: {UART.Framing.Line, separator: "\r\n"},
      id: :pid
    ]

    {uart_pid, gpio, gps_pid, phone_pid} = start(tty, options)
    {:noreply, {uart_pid, gpio, gps_pid, phone_pid}}
  end

  @impl GenServer
  def handle_cast(:listener_started, {uart_pid, _gpio, _gps_pid, _phone_pid} = state) do
    Logger.info("***Board starting listener")
    UART.controlling_process(uart_pid, Process.whereis(:listener))
    Nerves.Runtime.validate_firmware()
    GenServer.cast(self(), :start_phone)
    #GenServer.cast(self(), :start_gps)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start, {uart_pid, _gpio, _gps_pid, _phone_pid} = state) do
    Logger.info("***Board got start")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:start_phone, {uart_pid, gpio, gps_pid, phone_pid} = state) when phone_pid == 0 do
    Logger.info("***start_phone: #{inspect(state)}")
    {:noreply, {uart_pid, gpio, gps_pid, Phone.start(uart_pid)}}
  end

  @impl GenServer
  def handle_cast(:start_phone, state) do
    Logger.info("***Board start_phone already started")
    {:noreply, state}
  end

  def handle_cast(:start_gps, {uart_pid, gpio, gps_pid, phone_pid} = state) when gps_pid == 0 do
    Logger.info("***start_gps: #{inspect(state)}")
    {:noreply, {uart_pid, gpio, GPS.start(uart_pid), phone_pid}}
  end

  @impl GenServer
  def handle_cast(:start_gps, state) do
    Logger.info("***Board start_gps")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop_gps, {uart_pid, gpio, _gps_pid, phone_pid} = _state) do
    GPS.stop()
    {:noreply, {uart_pid, gpio, 0, phone_pid}}
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
    reset(uart_pid)
    {uart_pid, gpio, 0, 0}
  end

  # Reset Modem
  defp reset(pid) do
    UART.write(pid, "ATZ")
    :timer.sleep(500)
  end

  defp toggle_power(gpio) do
    :ok = GPIO.write(gpio, 0)
    :timer.sleep(200)
    :ok = GPIO.write(gpio, 1)
    :timer.sleep(200)
    :ok = GPIO.write(gpio, 0)
  end
end
