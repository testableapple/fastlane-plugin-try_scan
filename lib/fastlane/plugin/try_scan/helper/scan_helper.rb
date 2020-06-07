module TryScanManager
  module Helper
    module FastlaneScanHelper
      def self.report_options
        Scan::XCPrettyReporterOptionsGenerator.generate_from_scan_config
      end

      def self.valid_scan_keys
        Fastlane::Actions::ScanAction.available_options.map(&:key)
      end

      def self.print_scan_parameters(params)
        return if FastlaneCore::Helper.test?

        FastlaneCore::PrintTable.print_values(
          config: params,
          title: "Summary for scan #{Fastlane::VERSION}"
        )
      end

      def self.scan_options_from_try_scan_options(params)
        valid_scan_keys = Fastlane::Actions::ScanAction.available_options.map(&:key)
        params.select { |key, _| valid_scan_keys.include?(key) }
      end

      def self.options_from_configuration_file(params)
        config = FastlaneCore::Configuration.create(
          Fastlane::Actions::ScanAction.available_options,
          params
        )
        config_file = config.load_configuration_file(Scan.scanfile_name, nil, true)
        overridden_options = config_file ? config_file.options : {}

        FastlaneCore::Project.detect_projects(config)
        project = FastlaneCore::Project.new(config)

        imported_path = File.expand_path(Scan.scanfile_name)
        Dir.chdir(File.expand_path("..", project.path)) do
          if File.expand_path(Scan.scanfile_name) != imported_path
            config_file = config.load_configuration_file(Scan.scanfile_name, nil, true)
          end
          overridden_options.merge!(config_file.options) if config_file
        end
        overridden_options
      end

      def self.remove_preexisting_simulator_logs(params)
        return unless params[:include_simulator_logs]

        output_directory = report_options.instance_variable_get(:@output_directory)
        glob_pattern = "#{output_directory}/**/system_logs-*.{log,logarchive}"
        logs = Dir.glob(glob_pattern)
        FileUtils.rm_rf(logs)
      end

      def self.remove_preexisting_test_result_bundles(params)
        output_directory = report_options.instance_variable_get(:@output_directory)
        glob_pattern = "#{output_directory}/**/*.test_result"
        preexisting_test_result_bundles = Dir.glob(glob_pattern)
        if preexisting_test_result_bundles.size > 0
          FastlaneCore::UI.verbose("Removing pre-existing test_result bundles: ")
          preexisting_test_result_bundles.each { |bundle| FastlaneCore::UI.verbose("  #{bundle}") }
          FileUtils.rm_rf(preexisting_test_result_bundles)
        end
      end

      def self.remove_preexisting_xcresult_bundles(params)
        output_directory = report_options.instance_variable_get(:@output_directory)
        glob_pattern = "#{output_directory}/**/*.xcresult"
        preexisting_xcresult_bundles = Dir.glob(glob_pattern)
        if preexisting_xcresult_bundles.size > 0
          FastlaneCore::UI.verbose("Removing pre-existing xcresult bundles: ")
          preexisting_xcresult_bundles.each { |bundle| FastlaneCore::UI.verbose("  #{bundle}") }
          FileUtils.rm_rf(preexisting_xcresult_bundles)
        end
      end

      def self.remove_report_files
        output_files = report_options.instance_variable_get(:@output_files)
        output_directory = report_options.instance_variable_get(:@output_directory)

        unless output_files.empty?
          FastlaneCore::UI.verbose("Removing report files")
          output_files.each do |output_file|
            report_file = File.join(output_directory, output_file)
            FastlaneCore::UI.verbose("  #{report_file}")
            FileUtils.rm_f(report_file)
          end
        end
      end

      def self.update_xctestrun_after_build(scan_options)
        xctestrun_files = Dir.glob("#{Scan.config[:derived_data_path]}/Build/Products/*.xctestrun")
        FastlaneCore::UI.verbose("After building, found xctestrun files #{xctestrun_files} (choosing 1st)")
        scan_options[:xctestrun] = xctestrun_files.first
      end

      def self.remove_preexisting_xctestrun_files
        xctestrun_files = Dir.glob("#{Scan.config[:derived_data_path]}/Build/Products/*.xctestrun")
        FastlaneCore::UI.verbose("Before building, removing pre-existing xctestrun files: #{xctestrun_files}")
        FileUtils.rm_rf(xctestrun_files)
      end
    end
  end
end