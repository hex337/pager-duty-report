defmodule PagerDutyReport.Parsers.PagerDutyParser do
  def extract(:incidents, input) do
    %{"incidents" => incidents} = input
    incidents
  end

  def extract(:title, incident) do
    %{"title" => title} = incident
    title
  end

  def extract(:created_at, incident) do
    %{"created_at" => created_at} = incident
    convert_time_string(created_at)
  end

  def extract(:last_status_change_at, incident) do
    %{"last_status_change_at" => last_status_change_at} = incident
    convert_time_string(last_status_change_at)
  end

  def extract(:html_url, incident) do
    %{"html_url" => url} = incident
    url
  end

  def extract(:urgency, incident) do
    %{"urgency" => urgency} = incident
    convert_urgency(urgency)
  end

  defp convert_urgency(urgency) when urgency == "high", do: "H"
  defp convert_urgency(urgency) when urgency == "low", do: "L"

  defp convert_time_string(time_str) do
    {:ok, time} = Timex.parse(time_str, "{ISO:Extended}")
    time
  end
end
