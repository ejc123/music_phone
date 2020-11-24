defmodule Phone.GPS do
  use GenServer

  @moduledoc """
    Set up and use GPS
  """
  @on_duration 5000
  require Logger
  alias Circuits.UART

  def start_link, do: start_link([])
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :gps)

  def start(pid) do
    Logger.debug("***GPS: start self PID: #{inspect(self())}")
    Logger.debug("***GPS: start GPS PID: #{inspect(Phone.GPS)}")
    GenServer.cast(:gps, {:start, pid})
  end

  def stop() do
    GenServer.cast(:gps, :stop)
  end

  # Server

  @impl GenServer
  @spec init(any) :: {:ok, {-1, false}}
  def init(_state) do
    Logger.debug("***GPS: init PID: #{inspect(self())}")
    {:ok, {-1, false}}
  end

  @impl GenServer
  def handle_cast(:stop, {uart_pid, _} = _state) do
    stop_GPS(uart_pid)
    {:noreply, {uart_pid, true}}
  end

  @impl GenServer
  def handle_cast({:start, uart_pid}, _state) do
    Logger.debug("***GPS :start")
    start_GPS(uart_pid)
    schedule_work()
    {:noreply, {uart_pid, false}}
  end

  @impl GenServer
  def handle_info(:work, {uart_pid, stop?} = state) do
    Logger.debug("***GPS :work")
    get_gps_info(uart_pid)

    unless stop? do
      schedule_work()
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("Other message #{inspect(message)}")
    {:noreply, state}
  end

  # Power on GPS and start listener
  defp start_GPS(uart_pid) do
    UART.write(uart_pid, "AT+CGNSPWR=1")
    :timer.sleep(500)
  end

  defp stop_GPS(uart_pid) do
    UART.write(uart_pid, "AT+CGNSPWR=0")
    :timer.sleep(500)
  end

  # Check state of GPS
  #  defp check_GPS_state(uart_pid) do
  #    UART.write(uart_pid, "AT+CGNSPWR?")
  #  end

  # Set echo off
  #  defp echo_off(uart_pid) do
  #    UART.write(uart_pid, "ATE0")
  #  end

  # Set echo on
  #  defp echo_on(uart_pid) do
  #    UART.write(uart_pid, "ATE0")
  #  end

  # Get GPS info
  # Here's what we get back
  # {:nerves_uart, "ttyAMA0", ""}
  # {:nerves_uart, "ttyAMA0",
  #  "+CGNSINF: 1,1,20180516190139.000,46.893477,-96.803717,270.035,0.00,349.1,2,,1.1,2.0,1.6,,10,10,,,44,,"}
  # {:nerves_uart, "ttyAMA0", ""}
  # {:nerves_uart, "ttyAMA0", "OK"}
  # :ok

  defp get_gps_info(uart_pid) do
    UART.write(uart_pid, "AT+CGNSINF")
  end

  defp schedule_work() do
    Logger.debug("***GPS schedule_work")
    Process.send_after(self(), :work, @on_duration)
  end
end
