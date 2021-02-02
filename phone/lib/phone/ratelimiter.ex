defmodule Phone.RateLimiter do
  @moduledoc false

  use GenServer
  require Logger

  @max_per_period 2
  @sweep_after :timer.seconds(8 * 3600)
  @tab :numbers

  ## Client

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Phone.Limiter)
  end

  @spec log(any) :: <<_::40, _::_*8>>
  def log(phone) do
    case :ets.update_counter(@tab, phone, {2, 1}, {phone, 0}) do
      count when count > @max_per_period -> "never"
      _count -> "bushel"
    end
  end

  @spec dump :: {:ok, [tuple]}
  def dump() do
    phones = :ets.tab2list(@tab)
    Logger.info("Phone Numbers: #{inspect(phones)}")
    {:ok, phones}
  end

  ## Server
  @spec init(any) :: {:ok, %{}}
  def init(_) do
    Logger.info("***RateLimiter start PID: #{inspect(self())}")

    @tab =
      PersistentEts.new(@tab, "/data/numbers.tab", [
        :set,
        :named_table,
        :public
      ])

    schedule_sweep()
    {:ok, %{}}
  end

  def handle_info(:sweep, state) do
    Logger.debug("Sweeping requests")
    :ets.delete_all_objects(@tab)
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @sweep_after)
  end
end
