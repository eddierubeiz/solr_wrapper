module SolrWrapper
  # Configuraton that comes from static and dynamic sources.
  class Settings < Delegator

    def __getobj__
      @static_config # return object we are delegating to, required
    end

    alias static_config __getobj__

    def __setobj__(obj)
      @static_config = obj
    end

    def initialize(static_config)
      super
      @static_config = static_config
    end

    ##
    # Get the host this Solr instance is bound to
    def host
      '127.0.0.1'
    end

    ##
    # Get the port this Solr instance is running at
    def port
      @port ||= static_config.port
      @port ||= random_open_port.to_s
    end

    ##
    # Get a (likely) URL to the solr instance
    def url
      "http://#{host}:#{port}/solr/"
    end

    def instance_dir
      @instance_dir ||= static_config.instance_dir
      @instance_dir ||= File.join(Dir.tmpdir, File.basename(download_url, ".zip"))
    end

    def managed?
      File.exists?(instance_dir)
    end

    def download_url
      @download_url ||= static_config.url
      @download_url ||= default_download_url
    end

    def download_path
      @download_path ||= static_config.download_path
      @download_path ||= default_download_path
    end

    def version_file
      static_config.version_file || File.join(instance_dir, "VERSION")
    end

    def md5url
      "http://www.us.apache.org/dist/lucene/solr/#{static_config.version}/solr-#{static_config.version}.zip.md5"
    end

    def md5sum_path
      File.join(download_dir, File.basename(md5url))
    end

    def solr_binary
      File.join(instance_dir, "bin", "solr")
    end

    def tmp_save_dir
      @tmp_save_dir ||= Dir.mktmpdir
    end

    private

      def default_download_path
        File.join(download_dir, File.basename(download_url))
      end

      def download_dir
        @download_dir ||= static_config.download_dir
        @download_dir ||= Dir.tmpdir
        FileUtils.mkdir_p @download_dir
        @download_dir
      end


      def default_download_url
        @default_url ||= begin
          json = open(static_config.mirror_url).read
          doc = JSON.parse(json)
          doc['preferred'] + doc['path_info']
        end
      rescue SocketError
        "http://www.us.apache.org/dist/lucene/solr/#{static_config.version}/solr-#{static_config.version}.zip"
      end

      def random_open_port
        socket = Socket.new(:INET, :STREAM, 0)
        begin
          socket.bind(Addrinfo.tcp('127.0.0.1', 0))
          socket.local_address.ip_port
        ensure
          socket.close
        end
      end
  end
end