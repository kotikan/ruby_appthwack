command :status do |c|
	c.syntax = 'appthwack status [arguments]'
	c.summary = 'Check on the status of a running test'
	c.description = ''

	c.option '--project PROJECT', 'The project name of the running tests'
	c.option '--runid INT', 'The run ID of the test'


	c.action do |args, options|
		say_error 'Need project and run ID' if options.runid.nil? or options.project.nil?
		
		puts AppThwack::API.test_status? AppThwack::API.get_project_id(options.project), options.runid
	end
end