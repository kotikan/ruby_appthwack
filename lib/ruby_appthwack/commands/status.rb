#!/usr/bin/env ruby





APPTHWACK_API_KEY='2FCPLdbFMFfXAqahSSPeQWyeVqWZXUEPQO3d2epT'
if APPTHWACK_API_KEY == nil
  puts "Please set APPTHWACK_API_KEY.\n"
  exit 100
end




options = OpenStruct.new

p = OptionParser.new do |opt|
  opt.banner = "Usage: appthwack.rb [options]"

  opt.on('-o', '--operation OPERATION', 
    "The operation to perform: either 'run' a test or check the 'status' of a test") do |op|
    options.operation = op
  end

  opt.on('-r', '--run-id ID',  Integer, 
    "The run ID of the test in question") do |r|
    options.run_id = r
  end

  opt.on('-R', '--download-results',
    "Flag determining whether or not to download results") do |d|
    options.download_results = d
  end

  opt.on('-p', '--platform PLATFORM',
    "The device platform: 'ios' or 'android'") do |plat|
    options.platform = plat
  end

  opt.on('-S', '--scheme SCHEME',
    "The XCode build scheme for iOS") do |s|
    options.scheme = s
  end

  opt.on('-P', '--project NAME',
    "The project name") do |n|
    options.proj_name = n
  end

  opt.on('-d', '--device-pool NAME',
    "The device pool name") do |n|
    options.device_pool = n
  end

  opt.on('-w', '--wait',
    "Wait for the tests to finish?") do |w|
    options.wait = w
  end

  opt.on('-t', '--test-type TYPE',
    "The type of test to run: [calabash|junit]") do |t|
    options.test_type = t
  end

  opt.on('-a', '--app APP',
    "The location of the app file (can be a glob)") do |f|
    options.app_path = f
  end

  opt.on('-T', '--test-path APP',
    "The location of test package file (can be a glob)") do |f|
    options.test_path = f
  end
end.parse!

p ARGV



# actually run the code
operations = {
  'run' => Proc.new do
    

  end,

  'status' => Proc.new do
    puts test_status? options.proj_id, options.run_id
  end

}

operations[options.operation].call unless options.operation.nil?