
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

		        included = (o[:include_tests].map { |t| "'#{src}/#{t}'"}).join(' ')
		        excluded = if o[:exclude_tests]; "-x #{ (o[:exclude_tests].map { |t| "'#{calabash}/#{t}'"}).join(' ') }" else "" end
 
		        `zip #{src}.zip #{src} . -r #{excluded} -i '#{src}/support/*' '#{src}/step_definitions/*' #{included}`
		    end

		    src << '.zip'

		    return src
		end
	end
end