command :reports do |c|
	c.syntax = 'appthwack reports [arguments]'
	c.summary = 'Downloads reports and tidies reports'
	c.description = ''

	c.option '--project PROJECT', 'The project name of the running tests'
	c.option '--runid INT', 'The run ID of the test'
	c.option '--platform PLATFORM', 'The mobile platform of the app under test'
	c.option '--reports REPORTS', 'The location of the downloaded reports'

	c.action do |args, options|
		say_error 'Need project name and run ID' if options.runid.nil? or options.project.nil?
		
		options.proj_id = AppThwack::API.get_project_id(options.project)

		say_ok "Project ID: #{options.proj_id}"

		status = AppThwack::API.test_status? options.proj_id, options.runid

		say_error 'Project is not finished' unless status.eql? 'completed'

		say_ok 'Downloading reports...'

		reports = AppThwack::API.download_results options.proj_id, options.runid, options.reports

		say_ok "Downloaded raw reports to #{reports}"

		reports = AppThwack::Reports.extract_reports reports

		say_ok "Extracted reports to #{reports}"

	end
end