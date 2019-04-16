# PagerDutyReport

This is a script to print out an on-call summary from pager duty.

## Configuration

You will need to set up a `.env` file with your PagerDuty api key that looks like this:

```
PAGER_DUTY_TOKEN=token_value_here
```

You can also optionally set up a configuration yml file to set things like the service ids that you want to report on, and configure the timezone and definition of start of day and end of day for day/night page reporting. See the `config.yml.example` file as an example.

Configuration settings:
  * *service_ids*: An array of services to pull incidents from
  * *timezone*: A string for the timezone to query PagerDuty in
  * *start_of_day*: An integer to set when the day starts (for stats collecting)
  * *end_of_day*: An integer to set when the night starts (for stats collecting)
  * *template_type*: A string, either "md" or "wiki" that specifies the template format type

## Compiling Executable

To build a new executable, run `mix escript.build`.

## How to Run

Make sure you set up your .env with the example provided. You'll need a PagerDuty api key.

To run, just invoke `./pager_duty_report`

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pager_duty_report](https://hexdocs.pm/pager_duty_report).

