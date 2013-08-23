
command :run do |c|
  c.syntax = 'appthwack run [options]'
  c.summary = 'Packages tests and pushes them to AppThwack for Running'
  c.description = ''

  c.option '--platform PLATFORM', 'The platform of the application under test'
  c.option '--project PROJECT', 'Name of AppThwack project'
  c.option '--devices DEVICES', 'Name of device pool to use'
  c.option '--testtype TYPE', 'Scheme used to build iOS app'
  c.option '--app TEST', 'Path of the application (can be Glob syntax)'
  c.option '--test TEST', 'Path of the test package'
  c.option '--wait', 'Wait for the tests to complete'
  c.option '--scheme SCHEME', 'XCode scheme for packaging the IPA'
  c.option '--downloadresults', 'Decide whether or not to wait and download results'

  c.action do |args, options|

    options.proj_id   = AppThwack::API.get_project_id  options.project
    options.pool_id   = AppThwack::API.get_device_pool options.proj_id,  options.devices

    say_ok "Project ID: #{options.proj_id}"
    say_ok "Pool ID:    #{options.pool_id}"

    # Feature: list of tests to include via command line?
    if options.testtype.eql? 'calabash'
      options.test = AppThwack::Packaging.create_calabash_package options.proj_id, options.test
    end

    # if the platform is iOS, make an IPA before building
    if options.platform.eql? 'ios'
      options.app = AppThwack::Packaging.create_ipa(options.scheme)
    end

    # start by uploading the app
    options.app_id = (AppThwack::API.upload_file options.app)[:file_id]
    say_ok "App package ID:   #{options.app_id}"

    exit 3 if options.app_id.nil?

    # now upload the test package
    options.test_id = (AppThwack::API.upload_file options.test)[:file_id] 

    say_ok "Test packagae ID: #{options.test_id}"

    exit 4 if options.test_id.nil?

    params = {}

    params['calabash'] = { calabash: options.test_id }

    params['junit'] = { junit: options.test_id }

    result = AppThwack::API.start_test(
      File.basename(Dir.glob(options.app).first) + ' -- CLI', 
      options.proj_id,
      options.app_id, 
      options.pool_id, 
      params[options.testtype]
    )

    options.run_id = result[:run_id]

    say_ok "Run ID: #{options.run_id} with message: #{result[:message]}"

    exit 5 if options.run_id.nil?
    
    sleep 5

    print "\n"

    # wait for test to terminate
    until not AppThwack::API.test_running? options.proj_id, options.run_id or not options.wait
      print "."
      sleep 30
    end

    print "\n"

    # download the results and we should have waited
    if options.downloadresults and options.wait
      say_ok 'Downloading results...'
      
      zip = AppThwack::API.download_results options.proj_id, options.run_id

      say_ok "Results zip #{zip}"

      dst = AppThwack::Reports.convert_reports zip, options.platform

      say_ok "Converted reports to #{dst}"
    end

    say_ok "Tests started successfully"

  end
end
