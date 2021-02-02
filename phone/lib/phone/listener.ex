defmodule Phone.Listener do
  @moduledoc """
    This modules handles messages from the UART
  """
  use GenServer
  require Logger

  # Startup

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :listener)

  # Callbacks

  @impl GenServer
  @spec init(any) :: {:ok, any}
  def init(state) do
    Logger.info("***Listener start PID: #{inspect(self())}")
    {:ok, state}
  end

  @impl GenServer
  @spec handle_continue(:start, any) :: {:noreply, any}
  def handle_continue(:start, state) do
    :timer.sleep(200)
    GenServer.cast(:board, :listener_started)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:circuits_uart, _pid, <<"+CLIP: \"", phone::binary-size(12), _data::binary>>},
        state
      ) do
    Logger.info("***Listener Ringing #{inspect(phone)}")
    GenServer.cast(:phone, {:answer, Phone.RateLimiter.log(phone)})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:circuits_uart, _pid, "RING"}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:circuits_uart, _pid, "NO CARRIER"}, state) do
    Logger.info("*** NO CARRIER")
    GenServer.cast(:phone, :hangup)
    {:noreply, state}
  end

  # blackhole blank messages
  @impl GenServer
  def handle_info({:circuits_uart, _pid, ""}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.info("***Listener other message #{inspect(message)}")
    {:noreply, state}
  end
end
