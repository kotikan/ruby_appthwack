require 'json'
require 'pp'

module AppThwack::Reports
	class << self

		def extract_reports(reports)
			
			'unzipped_reports' if system "rm -rf unzipped_reports && unzip -qq #{reports} -d unzipped_reports"
		end

		# Converts Android reports into results readable by Cucumber plugin
		def convert_reports(reports, platform='android')
			# default to android folder
			intermediate_folders = 'calabash_tests_from_features.zip'

			dst = 'cucumber-html-reports'

			# unless platform is explicitly ios
			if platform.eql? 'ios'
				 intermediate_folders = 'calabash'
			end

			reports = extract_reports(reports)
			folders = Dir.entries(reports).select {|f| not f.eql? '.' and not f.eql? '..' }

			# extract for each of the devices
			folders.each do |f|

				# capitalize every word
				device = f.gsub('_', ' ').split.map(&:capitalize).join(' ')

				# original folder name
				folder_name = f

				puts device

				f = File.join(reports, f, intermediate_folders, 'raw_calabash_json_output.instrtxt')
				
				if File.exists? f
					features = []

					# now we just add the device prefix to each feature name to make it unique
					File.open(f, 'r') do |io|

						features = JSON.load(io)

						if not features.nil?
							
							features.each_index do |i|
								# append the device name to the feature name
								features[i]['name'] = "#{features[i]['name']} on #{device}"
							end
						end

						Dir.mkdir dst if not Dir.exists? dst

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
