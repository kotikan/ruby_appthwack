require 'json'
require 'pp'

module AppThwack::Reports
	class << self

		def extract_reports(reports)
			# make new folder name by chopping off .zip file
			out = reports.sub('.zip', '')
			# unzip then return the new folder name
			out if system "rm -rf #{out} && unzip -qq #{reports} -d #{out}"
		end

		# Converts Android reports into results readable by Cucumber plugin.
		# You should pass in the folder locatino of the reports
		def convert_reports(reports, platform='android')
			# default to android folder
			intermediate_folders = 'calabash_tests_from_features.zip'

			dst = 'cucumber-html-reports'

			# unless platform is explicitly ios
			if platform.eql? 'ios'
				 intermediate_folders = 'calabash'
			end

			folders = Dir["#{reports}/*"]

			# extract for each of the devices
			folders.each do |f|

				puts f
				# capitalize every word
				device = f.gsub('_', ' ').split.map(&:capitalize).join(' ')

				# try to find the next intermediate folder
				intermediate_folders = Dir["#{f}/calabash*"]

				report = File.join(intermediate_folders.first, 'raw_calabash_json_output.instrtxt')
				
				puts report 
				if File.exists? report
					features = []
					

					# now we just add the device prefix to each feature name to make it unique
					File.open(report, 'r') do |io|

						features = JSON.load(io)

						if not features.nil?
							
							features.each_index do |i|
								# append the device name to the feature name
								features[i]['name'] = "#{features[i]['name']} on #{device}"
							end
						end

						Dir.mkdir dst if not Dir.exists? dst

						# original folder name
						folder_name = f.sub(reports + "/", '')

						# now write out the new file
						File.open(File.join(dst, "#{Time.now.to_i}_#{folder_name}.json"), 'w') do |io|
							JSON.dump(features, io) unless features.nil?

						end
					end
				end
			end

			dst
		end

		
	end
end
