defmodule AppTime do
  @moduledoc false

  # use Timex

  def relative(nil, _locale, _timezone), do: ""

  def relative(date, locale, timezone) do
    maybe_relative(date, locale, timezone)
  end

  defp maybe_relative(datetime, locale, timezone) do
    tz = get_timezone(timezone)
    locale = get_locale(locale)
    datetime = Timex.Timezone.convert(datetime, tz)
    now = Timex.now(tz)
    a_month_ago = Timex.shift(now, months: -1)
    past? = Timex.before?(datetime, a_month_ago)

    if past? do
      Timex.lformat!(datetime, "{YYYY}-{0M}-{0D}", locale)
    else
      Timex.lformat!(datetime, "{relative}", locale, :relative)
    end
  end

  defp get_timezone(timezone) do
    timezone || Timex.Timezone.local()
  end

  defp get_locale(nil), do: "en"

  defp get_locale(locale) do
    to_string(locale)
  end
end
