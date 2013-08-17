command :build do |c|
  c.syntax = 'appthwack run [options]'
  c.summary = 'Package tests and push them to AppThwack for Running'
  c.description = ''

  c.option '--platform PLATFORM', 'The platform of the application under test'
  c.option '--project PROJECT', 'Name of AppThwack project'
  c.option '--configuration CONFIGURATION', 'Configuration used to build'
  c.option '--devices DEVICES', 'Name of device pool to use'
  c.option '--scheme SCHEME', 'Scheme used to build app'
  c.option '--[no-]clean', 'Clean project before building'
  c.option '--[no-]archive', 'Archive project after building'

  c.action do |args, options|

    options.proj_id     = get_project_id  options.project
    options.pool_id   = get_device_pool options.proj_id,  options.devices

    puts "Project ID: #{options.proj_id}"
    puts "Pool ID:    #{options.pool_id}"

    # Feature: list of tests to include via command line?
    if options.test_type.eql? 'calabash'
      options.test_path = create_calabash_package options.proj_id, options.test_path
    end

    # if the platform is iOS, make an IPA before building
    if options.platform.eql? 'ios'
      options.app_path = create_ipa(options.scheme)
    end

    options.app_id = (upload_file options.app_path)[:file_id]
    puts "App package ID:   #{options.app_id}"

    exit 3 if options.app_id.nil?

    options.test_id = (upload_file options.test_path)[:file_id] 

    puts "Test packagae ID: #{options.test_id}"

    exit 4 if options.test_id.nil?

    params = {}

    params['calabash'] = { calabash: options.test_id }

    params['junit'] = { junit: options.test_id }

    result = start_test(
      File.basename(options.app_path), 
      options.proj_id,
      options.app_id, 
      options.pool_id, 
      params[options.test_type]
    )

    options.run_id = result[:run_id]

    puts "Run ID: #{options.run_id} with message: #{result[:message]}"

    exit 5 if options.run_id.nil?

    # wait for test to terminate
    sleep 5

    until not test_running? options.proj_id, options.run_id or not options.wait
      print "."
      sleep 30
    end

    # download the results
    if options.download_results
      zip = download_results proj_id, run_id
      puts "Results ZIP: #{zip}"
    end

    validate_xcode_version!

    @workspace = options.workspace
    @project = options.project unless @workspace

    @xcodebuild_info = Shenzhen::XcodeBuild.info(:workspace => @workspace, :project => @project)

    @scheme = options.scheme
    @configuration = options.configuration

    determine_workspace_or_project! unless @workspace || @project

    determine_configuration! unless @configuration
    say_error "Configuration #{@configuration} not found" and abort unless (@xcodebuild_info.build_configurations.include?(@configuration) rescue false)

    determine_scheme! unless @scheme
    say_error "Scheme #{@scheme} not found" and abort unless (@xcodebuild_info.schemes.include?(@scheme) rescue false)

    say_warning "Building \"#{@workspace || @project}\" with Scheme \"#{@scheme}\" and Configuration \"#{@configuration}\"\n" unless options.quiet

    log "xcodebuild", (@workspace || @project)

    flags = []
    flags << "-sdk iphoneos"
    flags << "-workspace '#{@workspace}'" if @workspace
    flags << "-project '#{@project}'" if @project
    flags << "-scheme '#{@scheme}'" if @scheme
    flags << "-configuration '#{@configuration}'"

    actions = []
    actions << :clean unless options.clean == false
    actions << :build
    actions << :archive unless options.archive == false

    ENV['CC'] = nil # Fix for RVM
    abort unless system %{xcodebuild #{flags.join(' ')} #{actions.join(' ')} 1> /dev/null}

    @target, @xcodebuild_settings = Shenzhen::XcodeBuild.settings(*flags).detect{|target, settings| settings['WRAPPER_EXTENSION'] == "app"}
    say_error "App settings could not be found." and abort unless @xcodebuild_settings

    @app_path = File.join(@xcodebuild_settings['BUILT_PRODUCTS_DIR'], @xcodebuild_settings['WRAPPER_NAME'])
    @dsym_path = @app_path + ".dSYM"
    @dsym_filename = "#{@xcodebuild_settings['WRAPPER_NAME']}.dSYM"
    @ipa_name = @xcodebuild_settings['WRAPPER_NAME'].gsub(@xcodebuild_settings['WRAPPER_SUFFIX'], "") + ".ipa"
    @ipa_path = File.join(Dir.pwd, @ipa_name)

    log "xcrun", "PackageApplication"
    abort unless system %{xcrun -sdk iphoneos PackageApplication -v "#{@app_path}" -o "#{@ipa_path}" --embed "#{@dsym_path}" 1> /dev/null}

    log "zip", @dsym_filename
    abort unless system %{cp -r "#{@dsym_path}" . && zip -r "#{@dsym_filename}.zip" "#{@dsym_filename}" >/dev/null && rm -rf "#{@dsym_filename}"}

    say_ok "#{File.basename(@ipa_path)} successfully built" unless options.quiet
  end

  private

  def validate_xcode_version!
    version = Shenzhen::XcodeBuild.version
    say_error "Shenzhen requires Xcode 4 (found #{version}). Please install or switch to the latest Xcode." and abort if version < "4.0.0"
  end

  def determine_workspace_or_project!
    workspaces, projects = Dir["*.xcworkspace"], Dir["*.xcodeproj"]

    if workspaces.empty?
      if projects.empty?
        say_error "No Xcode projects or workspaces found in current directory" and abort
      else
        if projects.length == 1
          @project = projects.first
        else
          @project = choose "Select a project:", *projects
        end
      end
    else
      if workspaces.length == 1
        @workspace = workspaces.first
      else
        @workspace = choose "Select a workspace:", *workspaces
      end
    end
  end

  def determine_scheme!
    if @xcodebuild_info.schemes.length == 1
      @scheme = @xcodebuild_info.schemes.first
    else
      @scheme = choose "Select a scheme:", *@xcodebuild_info.schemes
    end
  end

  def determine_configuration!
    configurations = @xcodebuild_info.build_configurations rescue []
    if configurations.nil? or configurations.empty? or configurations.include?("Debug")
      @configuration = "Debug"
    elsif configurations.length == 1
      @configuration = configurations.first
    end

    if @configuration
      say_warning "Configuration was not passed, defaulting to #{@configuration}"
    else
      @configuration = choose "Select a configuration:", *configurations
    end
  end
end
