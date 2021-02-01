defmodule Phone.Listener do
  use GenServer
  require Logger

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: :listener)

  @impl GenServer
  @spec init(any) :: {:ok, {-1, false}, {:continue, :start}}
  def init(_state) do
    Logger.debug("Listener Started, PID: #{inspect(self())}")
    {:ok, {-1, false}, {:continue, :start}}
  end

  # Handle messages from UART

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
    Logger.info("*** Ringing #{inspect(phone)}")
    GenServer.cast(:phone, :answer)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:circuits_uart, _pid, "RING"}, state) do
    Logger.info("*** Ringing")
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
  def handle_info(msg, state) do
    Logger.debug("***circuits: #{inspect(msg)}")
    {:noreply, state}
  end
end
