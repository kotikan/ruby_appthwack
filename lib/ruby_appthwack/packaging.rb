
module AppThwack::Packaging

	class << self
		def create_ipa(scheme)
		  #uses Shenzhen gem
		  abort unless system "ipa build --scheme #{scheme} --configuration Release --no-archive"

		  return Dir.glob('*.ipa').first
		end

		def create_calabash_package proj_id, src, opts = {}
		    o = { :include_tests=> ["*.feature"], :exclude_tests=> nil}.merge opts

		    # create the archive if it doesn't already exist
		    unless File.extname(src) == '.zip'
		        # delete any old archives we have laying about
		        File.delete(src + '.zip') if File.exists?(src + '.zip')

		        # We break the source file name into two parts since 'features' must be the top level directory.
		        # the name of the folder containing the tests (usually 'features')
 				srcn = File.basename(src)
 				# the path of the folder containing the tests
 				srcp = File.dirname(src)

		        included = (o[:include_tests].map { |t| "'#{srcn}/#{t}'"}).join(' ')
		        excluded = if o[:exclude_tests]; "-x #{ (o[:exclude_tests].map { |t| "'#{srcn}/#{t}'"}).join(' ') }" else "" end
 
 				

		        `cd '#{srcp}' && zip #{srcn}.zip #{srcn} -r #{excluded} -i '#{srcn}/support/*' '#{srcn}/step_definitions/*' #{included}`
		    end

		    src << '.zip'

		    return src
		end
	end
end