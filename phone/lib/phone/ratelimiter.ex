defmodule Phone.RateLimiter do
  use GenServer
  require Logger

  @max_per_period 2
  @sweep_after :timer.seconds(8 * 3600)
  @tab :numbers

  ## Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Phone.Limiter)
  end

  def log(phone) do
    case :ets.update_counter(@tab, phone, {2, 1}, {phone, 0}) do
      count when count > @max_per_period -> "never"
      _count -> "bushel"
    end
  end

  def dump() do
    phones = :ets.tab2list(@tab)
    Logger.info("Phone Numbers: #{inspect(phones)}")
    {:ok, phones}
  end

  ## Server
  def init(_) do
    Logger.debug("RateLimiter starting #{inspect(self())}")
    @tab =
      PersistentEts.new(@tab, "/data/numbers.tab", [
        :set,
        :named_table,
        :public,
        read_concurrency: true
#        write_concurrency: true
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
