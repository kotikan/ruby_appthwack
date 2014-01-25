
require 'ostruct'
require "json"
require "typhoeus"

module AppThwack::API

  class << self
      def get_project_id(name)
        res = 
          JSON.parse(
            Typhoeus.get(
              "https://appthwack.com/api/project/",
              userpwd: "#{ENV['APPTHWACK_API_KEY']}:"
            ).body
          )
        
        return (res.select { |project| project['name'].eql? name }).first['id']
      end

      def get_device_pool(proj_id, name)
        
        res = 
          JSON.parse(
            Typhoeus.get(
              "https://appthwack.com/api/devicepool/#{proj_id}",
              userpwd: "#{ENV['APPTHWACK_API_KEY']}:"
            ).body
          )
        
        return (res.select { |pool| pool['name'].eql? name }).first['id']
      end

      
      def download_file(src, dst)
        # We use curl to download the file to avoid running out of RAM
        return dst if system "curl -X GET '#{src}' -o '#{dst}' --silent"
      end

      def upload_file(src)
        f = Dir.glob( src ).first

        res = JSON.parse(
          Typhoeus.post(
            "https://appthwack.com/api/file",
            userpwd: "#{ENV['APPTHWACK_API_KEY']}:",
            params: {
              name: File.basename(f)
            },
            body: {
              file: File.open(f,"r")
            }
          ).body
        )
        
        return { :file_id => res["file_id"], :succeeded? => res['message'].nil?, :message => res['message'] }
      end

      def start_test(name, proj_id, app_id, pool_id, params = {})

        params.merge! project: proj_id, name: name, app: app_id, pool: pool_id

        res = JSON.parse( 
          Typhoeus.post(
            "https://appthwack.com/api/run",
            userpwd: "#{ENV['APPTHWACK_API_KEY']}:",
            params: params
          ).body
        )
        
        return { :run_id => res['run_id'], :succeeded? => res['message'].nil?, :message => res['message'] }
      end

      def test_status?(proj_id, run_id)
        res = JSON.parse(
            Typhoeus.get(
              "https://appthwack.com/api/run/#{proj_id}/#{run_id}/status",
              userpwd: "#{ENV['APPTHWACK_API_KEY']}:",
            ).body
        )

        return res['status']
      end

      def test_running?(proj_id, run_id)
        return test_status?( proj_id, run_id ) != 'completed'
      end

      def download_results(proj_id, run_id, output)

        resp = Typhoeus.get(
          "https://appthwack.com/api/run/#{proj_id}/#{run_id}",
          userpwd: "#{ENV['APPTHWACK_API_KEY']}:",
          params: {
            format: "archive"
          }
        )

        # we save the reports to a zip file
        return ( download_file resp.headers_hash['Location'], output + '.zip') if resp.code == 303
      end
  end
end