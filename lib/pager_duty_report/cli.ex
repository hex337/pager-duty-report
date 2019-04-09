defmodule PagerDutyReport.CLI do
  alias PagerDutyReport.Parsers.PagerDutyParser

  def main(args) do
    Envy.load([".env"])

    spinner_format = [
      frames: :braille,
      text: "Fetching Incidents...",
      done: "Finished!",
      spinner_color: IO.ANSI.magenta
    ]

    since_until = get_since_until()

    {:ok, formatted_until} = Timex.format(since_until[:until], "{ISO:Extended}")
    {:ok, formatted_since} = Timex.format(since_until[:since], "{ISO:Extended}")

    params = [
      {"since", formatted_since},
      {"until", formatted_until},
      {"service_ids[]", "PV528UG"},
      {"service_ids[]", "PEZPT4B"},
      {"limit", 100},
      {"time_zone", "US/Pacific"}
    ]

    request = ProgressBar.render_spinner(spinner_format, fn ->
      PagerDutyReport.PagerDutyClient.request("incidents", params)
    end)

    {:ok, response} = parse_request(request)
    parsed_incidents = PagerDutyParser.extract(:incidents, response)
    incidents = Enum.map(parsed_incidents, &parse_incident/1)

    template_params = [
      until: since_until[:until],
      since: since_until[:since],
      incidents_by_date: group_incidents_by_day(incidents)
    ]

    template_name = get_template_name()

    IO.puts generate_output(template_params, template_name)
  end

  defp get_since_until() do
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
    IO.puts response.status_code
    Poison.decode(response.body)
  end

  defp parse_request({_, response}) do
    IO.puts "Error parsing request: #{response.body}"
  end

  defp parse_incident(incident) do
    %{
      title: PagerDutyParser.extract(:title, incident),
      created_at: PagerDutyParser.extract(:created_at, incident),
      last_status_change_at: PagerDutyParser.extract(:last_status_change_at, incident),
      url: PagerDutyParser.extract(:html_url, incident),
      urgency: PagerDutyParser.extract(:urgency, incident)
    }
  end

  defp group_incidents_by_day(incidents) do
    grouped_by_date = Enum.group_by(incidents, fn (incident) ->
      incident[:created_at]
      |> Timex.format("%a %b %d", :strftime)
      |> elem(1)
    end)

    # We just want to make sure the groups are sorted by day.
    Enum.sort_by(grouped_by_date, fn {_date, grouped_incidents} ->
      List.first(grouped_incidents)[:created_at]
      |> Timex.format("%Y-%m-%d %H:%M:%S", :strftime)
      |> elem(1)
    end)
  end

  defp generate_output(params, template_name) do
    file_path = "lib/pager_duty_report/templates/#{template_name}.md.eex"
    EEx.eval_file(file_path, params)
  end
end
