command :convert do |c|
  c.syntax = 'appthwack convert [options]'
  c.option '--reports STRING', String, 'Location of reports folder.'
  c.option '--platform STRING', String, 'Platform of tests.'
  c.summary = 'Converts the AppThwack results into something readable for the Jenkins'
  c.description = ''

  c.action do |args, options|
    dst = AppThwack::Reports.convert_reports options.reports, options.platform

    say_ok "Converted reports to #{dst}"
  end
end