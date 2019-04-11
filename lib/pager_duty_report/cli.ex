defmodule PagerDutyReport.CLI do
  alias PagerDutyReport.Parsers.PagerDutyParser

  def main(args) do
    Envy.load([".env"])
    {:ok, config} = parse_config()

    spinner_format = [
      frames: :braille,
      text: "Fetching Incidents...",
      done: "Finished!",
      spinner_color: IO.ANSI.magenta
    ]

    since_until = get_since_until(config)

    {:ok, formatted_until} = Timex.format(since_until[:until], "{ISO:Extended}")
    {:ok, formatted_since} = Timex.format(since_until[:since], "{ISO:Extended}")

    format_params = [
      {"since", formatted_since},
      {"until", formatted_until},
      {"limit", 100},
      {"time_zone", get_timezone(config)}
    ]

    params = get_service_ids(config)
             |> Enum.map(fn sid -> {"service_ids[]", sid} end)
             |> Enum.concat(format_params)

    request = ProgressBar.render_spinner(spinner_format, fn ->
      PagerDutyReport.PagerDutyClient.request("incidents", params)
    end)

    {:ok, response} = parse_request(request)
    parsed_incidents = PagerDutyParser.extract(:incidents, response)
    incidents = Enum.map(parsed_incidents, &parse_incident/1)
    stats = calculate_stats(incidents, config)

    template_params = [
      until: since_until[:until],
      since: since_until[:since],
      incidents_by_date: group_incidents_by_day(incidents),
      stats: stats,
      start_of_day: start_of_day(config),
      start_of_night: start_of_night(config)
    ]

    template_name = get_template_name()

    IO.puts generate_output(template_params, template_name)
  end

  defp parse_config() do
    path = Path.join(File.cwd!(), "config.yml")
    parse_config_from_file(path)
  end

  defp parse_config_from_file(path) do
    case File.exists?(path) do
      true -> YamlElixir.read_from_file(path)
      false -> {:ok, %{}}
    end
  end

  defp get_timezone(config) do
    Map.get(config, "timezone", "US/Pacific")
  end

  defp get_service_ids(config) do
    Map.get(config, "service_ids", [])
  end

  defp get_since_until(config) do
    default_until_time = Timex.beginning_of_week(Timex.now, :tue) |> Timex.shift(hours: 10)
    default_since_time = Timex.shift(default_until_time, days: -7)

    %{
      since: default_since_time,
      until: default_until_time
    }
  end

  defp get_template_name() do
    "basic"
  end

  defp parse_request({:ok, response}) do
    Poison.decode(response.body)
  end

  defp parse_request({_, response}) do
    IO.puts "Error parsing request: #{response.body}"
  end

  defp parse_incident(incident) do
    %{
      created_at: PagerDutyParser.extract(:created_at, incident),
      id: PagerDutyParser.extract(:id, incident),
      last_status_change_at: PagerDutyParser.extract(:last_status_change_at, incident),
      title: PagerDutyParser.extract(:title, incident),
      url: PagerDutyParser.extract(:html_url, incident),
      urgency: PagerDutyParser.extract(:urgency, incident)
    }
  end

  defp group_incidents_by_day(incidents) do
    grouped_by_date = Enum.group_by(incidents, fn (incident) ->
      with {:ok, formatted_date} <- Timex.format(incident[:created_at], "%a %b %d", :strftime)
      do
        formatted_date
      end
    end)

    # We just want to make sure the groups are sorted by day.
    Enum.sort_by(grouped_by_date, fn {_date, grouped_incidents} ->
      incident_time = List.first(grouped_incidents)[:created_at]
      with {:ok, formatted_date} <- Timex.format(incident_time, "%Y-%m-%d %H:%M:%S", :strftime)
      do
        formatted_date
      end
    end)
  end

  defp calculate_stats(incidents, config) do
    total_count = Enum.count(incidents)
    day_time_count = Enum.count(incidents, fn incident -> is_during_day?(incident, config) end)
    night_time_count = Enum.count(incidents, fn incident -> is_during_night?(incident, config) end)

    affected_hours = 0

    %{
      total_incidents: total_count,
      day_time_pages: day_time_count,
      night_time_pages: night_time_count,
      affected_hours: affected_hours
    }
  end

  defp is_during_day?(incident, config) do
    beginning_of_day = Timex.beginning_of_day(incident[:created_at])
    start_of_day_time = beginning_of_day |> Timex.shift(hours: start_of_day(config))
    end_of_day_time = beginning_of_day |> Timex.shift(hours: start_of_night(config))

    Timex.between?(incident[:created_at], start_of_day_time, end_of_day_time, [inclusive: true])
  end

  defp is_during_night?(incident, config) do
    beginning_of_day = Timex.beginning_of_day(incident[:created_at])
    end_of_day = Timex.end_of_day(incident[:created_at])

    start_of_night_time = beginning_of_day |> Timex.shift(hours: start_of_night(config))
    end_of_night_time = beginning_of_day |> Timex.shift(hours: start_of_day(config))

    Timex.between?(incident[:created_at], beginning_of_day, end_of_night_time, [inclusive: true]) ||
      Timex.between?(incident[:created_at], start_of_night_time, end_of_day, [inclusive: true])
  end

  defp start_of_day(config) do
    Map.get(config, "start_of_day", 8) # Default is 8am
  end

  defp start_of_night(config) do
    Map.get(config, "start_of_night", 21) # Default is 9pm
  end

  defp generate_output(params, template_name) do
    file_path = "lib/pager_duty_report/templates/#{template_name}.md.eex"
    EEx.eval_file(file_path, params, [trim: true])
  end
end
