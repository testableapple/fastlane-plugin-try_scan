module TryScanManager
  class Runner

    FastlaneScanHelper = TryScanManager::Helper::FastlaneScanHelper

    def initialize(options = {})
      @options = options
      @options[:try_count] = 1 if @options[:try_count] < 1
    end

    def run
      print_summary
      @attempt = 1
      begin
        essential_scan_config_updates
        warn_of_performing_attempts
        clear_preexisting_data
        Scan::Runner.new.run
        print_try_scan_result
        return true
      rescue FastlaneCore::Interface::FastlaneTestFailure => _
        failed_tests = failed_tests_from_xcresult_report
        print_try_scan_result(failed_tests_count: failed_tests.size)
        return false if finish?

        @attempt += 1
        update_scan_options(failed_tests)
        retry
      rescue FastlaneCore::Interface::FastlaneBuildFailure => _
        return false if finish?

        @attempt += 1
        retry
      end
    end

    def finish?
      @attempt >= @options[:try_count]
    end

    def print_summary
      return if FastlaneCore::Helper.test?

      scan_actual_params = Scan.config.values(ask: false)
      scan_available_keys = Scan.config.available_options.map(&:key)
      try_scan_params = @options.reject { |try_scan_key, _| scan_available_keys.include?(try_scan_key) }
      FastlaneCore::PrintTable.print_values(
        config: try_scan_params,
        title: "Summary for try_scan #{Fastlane::TryScan::VERSION}"
      )
      FastlaneCore::PrintTable.print_values(
        config: scan_actual_params,
        title: "Summary for scan #{Fastlane::VERSION}"
      )
    end

    def warn_of_performing_attempts
      FastlaneCore::UI.important("TryScan: Getting started #{ordinalized_attempt} shot\n")
    end

    def clear_preexisting_data
      FastlaneScanHelper.remove_preexisting_simulator_logs(@options)
      FastlaneScanHelper.remove_preexisting_test_result_bundles(@options)
      FastlaneScanHelper.remove_preexisting_xcresult_bundles(@options)
      FastlaneScanHelper.remove_report_files
    end

    def print_try_scan_result(failed_tests_count: 0)
      FastlaneCore::UI.important("TryScan: result after #{ordinalized_attempt} shot 👇")
      FastlaneCore::PrintTable.print_values(
        config: {"Number of tests" => tests_count_from_xcresult_report, "Number of failures" => failed_tests_count},
        title: "Test Results"
      )
    end

    def ordinalized_attempt
      case @attempt
      when 1
        "#{@attempt}st"
      when 2
        "#{@attempt}nd"
      when 3
        "#{@attempt}rd"
      else
        "#{@attempt}th"
      end
    end

    def update_scan_options(failed_tests)
      scan_options = FastlaneScanHelper.scan_options_from_try_scan_options(@options)
      scan_options[:only_testing] = failed_tests
      scan_options[:skip_build] = true
      scan_options[:test_without_building] = true
      scan_options.delete(:skip_testing)
      Scan.cache.clear
      scan_options.each do |key, val|
        next if val.nil?

        Scan.config.set(key, val)
        FastlaneCore::UI.verbose("\tSetting #{key.to_s} to #{val}")
      end
    end

    def essential_scan_config_updates
      Scan.config[:result_bundle] = true
      Scan.config[:build_for_testing] = nil if Scan.config[:build_for_testing]
      Scan.config[:xcargs].slice!('build-for-testing') if Scan.config[:xcargs]&.include?('build-for-testing')
    end

    def parse_xcresult_report
      report_options = FastlaneScanHelper.report_options
      output_directory = report_options.instance_variable_get(:@output_directory)
      xcresult_report_files = Dir["#{output_directory}/*.xcresult"]
      raise FastlaneCore::UI.test_failure!('There are no xcresult reports to parse') if xcresult_report_files.empty?

      FastlaneCore::UI.verbose("Parsing xcresult report by path: '#{xcresult_report_files.first}'")
      JSON.parse(`xcrun xcresulttool get --format json --path #{xcresult_report_files.first}`)
    end

    def failed_tests_from_xcresult_report
      only_testing = []
      parse_xcresult_report['issues']['testFailureSummaries']['_values'].each do |failed_test|
        suite_name = failed_test['producingTarget']['_value']
        test_path = failed_test['testCaseName']['_value']
        begin
          test_class = test_path.split('.').first
          test_name = test_path.split('.')[1].split('(').first
        rescue NoMethodError => _
          test_class = test_path.split('[')[1].split(' ').first
          test_name = test_path.split(' ')[1].split(']').first
        end
        only_testing << "#{suite_name}/#{test_class}/#{test_name}"
      end
      only_testing
    end

    def tests_count_from_xcresult_report
      parse_xcresult_report['metrics']['testsCount']['_value']
    end
  end
end
