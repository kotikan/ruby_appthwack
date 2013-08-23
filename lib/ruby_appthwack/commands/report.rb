command :reports do |c|
	c.syntax = 'appthwack reports [arguments]'
	c.summary = 'Downloads reports and tidies reports'
	c.description = ''

	c.option '--project PROJECT', 'The project name of the running tests'
	c.option '--runid INT', 'The run ID of the test'
	c.option '--platform PLATFORM', 'The mobile platform of the app under test'

	c.action do |args, options|
		say_error 'Need project name and run ID' if options.runid.nil? or options.project.nil?
		
		options.proj_id = AppThwack::API.get_project_id(options.project)

		say_ok "Project ID: #{options.proj_id}"

		status = AppThwack::API.test_status? options.proj_id, options.runid

		say_error 'Project is not finished' unless status.eql? 'completed'

		say_ok 'Downloading reports...'

		reports = AppThwack::API.download_results options.proj_id, options.runid

		say_ok "Downloaded raw reports: #{reports}"

		AppThwack::Reports.convert_reports reports, options.platform

		say_ok 'Converted reports'
	end
end