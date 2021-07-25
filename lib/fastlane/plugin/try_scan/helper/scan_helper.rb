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
        params.select { |key, _| valid_scan_keys.include?(key) }
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

      def self.backup_output_folder(attempt)
        output_files = report_options.instance_variable_get(:@output_files)
        output_directory = report_options.instance_variable_get(:@output_directory)

        unless output_files.empty?
          FastlaneCore::UI.verbose("Back up an output folder")
          backup = "#{output_directory}_#{attempt}"
          FileUtils.mkdir_p(backup)
          FileUtils.copy_entry(output_directory, backup)
        end
      end

      def self.clean_up_backup
        output_directory = report_options.instance_variable_get(:@output_directory)

        Dir["#{output_directory}_*"].each do |backup|
          FastlaneCore::UI.verbose("Removing backup: #{backup}")
          FileUtils.rm_rf(backup)
        end
      end
    end
  end
end
