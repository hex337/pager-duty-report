defmodule PagerDutyReport.PagerDutyClient do
  def request(uri_path, params) do
    pager_duty_token = System.get_env("PAGER_DUTY_TOKEN")
    headers = [
      "Authorization": "Token token=#{pager_duty_token}",
      "Accept": "application/vnd.pagerduty+json;version=2"
    ]

    base_url = "https://api.pagerduty.com/"
    formatted_url = "#{base_url}#{uri_path}"

    options = [
      params: params
    ]

    HTTPoison.get(formatted_url, headers, options)
  end
end
