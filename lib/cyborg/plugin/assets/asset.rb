module Cyborg
  module Assets
    class AssetType
      attr_reader :plugin, :base

      def initialize(plugin, base)
        @base = base
        @plugin = plugin
      end

      def find_files
        if @files
          @files
        else
          files = Dir[File.join(base, "*.#{ext}")].reject do |f|
            # Filter out partials
            File.basename(f).start_with?('_')
          end

          @files = files if Cyborg.production?
          files
        end
      end

      def filter_files(names=nil)
        names = [names].flatten.compact.map do |n|
          File.basename(n).sub(/(\..+)$/,'')
        end

        if !names.empty?
          find_files.select do |f|
            names.include? File.basename(f).sub(/(\..+)$/,'')
          end
        else
          find_files
        end
      end

      def versioned(path)
        File.basename(path).sub(/(\.\w+)$/, '-'+plugin.version+'\1')
      end

      def local_path(file)
        destination(file).sub(plugin.root+'/','')
      end

      def build_success(file)
        log_success "Built: #{local_path(file)}"
      end

      def build_failure(file)
        msg = "\nFAILED TO BUILD"
        msg += ": #{local_path(file)}" if file
        log_error msg
      end

      def log_success( msg )
        STDOUT.puts msg.to_s.colorize(:green)
      end

      def log_error( msg )
        STDERR.puts msg.to_s.colorize(:red)
      end

      # Determine if an NPM module is installed by checking paths with `npm ls`
      # Returns path to binary if installed
      def find_node_module(cmd)
        response = Open3.capture3("npm ls #{cmd}")

        # Look in local `./node_modules` path.
        # Be sure stderr is empty (the second argument returned by capture3)
        if response[1].empty?
          "$(npm bin)/#{cmd}"

        # Check global module path
        elsif Open3.capture3("npm ls -g #{cmd}")[1].empty?
          cmd
        end
      end

      def npm_command(cmd)
        cmd = cmd.split(' ')
        path = find_node_module(cmd.shift)
        if path
          system "#{path} #{cmd.join(' ')}"
        end
      end

      def destination(path)
        plugin.asset_path(versioned(path))
      end

      def url(path)
        plugin.asset_url(versioned(path))
      end

      def urls(names=nil)
        filter_files(names).map{ |file| url(file) }
      end

      def watch
        puts "Watching for changes to #{base.sub(plugin.root+'/', '')}...".colorize(:light_yellow)

        Thread.new {
          listener = Listen.to(base) do |modified, added, removed|
            change(modified, added, removed)
          end

          listener.start # not blocking
          sleep
        }
      end

      def change(modified, added, removed)
        puts "Added: #{file_event(added)}".colorize(:light_green)       unless added.empty?
        puts "Removed: #{file_event(removed)}".colorize(:light_red)   unless removed.empty?
        puts "Modified: #{file_event(modified)}".colorize(:light_yellow) unless modified.empty?

        build
      end

      def file_event(files)
        list = files.map { |f| f.sub(base+'/', '') }.join("  \n")
        list = "  \n#{files}" if 1 < files.size

        list 
      end

      def compress(file)
        return unless Cyborg.production?

        mtime = File.mtime(file)
        gz_file = "#{file}.gz"
        return if File.exist?(gz_file) && File.mtime(gz_file) >= mtime

        File.open(gz_file, "wb") do |dest|
          gz = Zlib::GzipWriter.new(dest, Zlib::BEST_COMPRESSION)
          gz.mtime = mtime.to_i
          IO.copy_stream(open(file), gz)
          gz.close
        end

        File.utime(mtime, mtime, gz_file)
      end
    end
  end
end
