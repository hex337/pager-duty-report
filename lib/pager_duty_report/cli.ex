defmodule PagerDutyReport.CLI do
  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [start_date: :string])

    IO.inspect opts

    data = ProgressBar.render_spinner([frames: :braille, spinner_color: IO.ANSI.magenta], fn ->
      :timer.sleep 2000
    end)
  end
end
