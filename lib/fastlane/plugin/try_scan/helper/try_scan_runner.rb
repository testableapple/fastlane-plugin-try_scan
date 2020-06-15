module TryScanManager
  class Runner

    FastlaneScanHelper = TryScanManager::Helper::FastlaneScanHelper

    def initialize(options = {})
      @options = options
    end

    def run
      update_scan_config
      print_summary
      @attempt = 1
      begin
        warn_of_performing_attempts
        clear_preexisting_data
        Scan::Runner.new.run
        print_parallel_scan_result
        return true
      rescue FastlaneCore::Interface::FastlaneTestFailure => _
        failed_tests = extract_failed_tests
        print_parallel_scan_result(failed_tests_count: failed_tests.size)
        update_scan_junit_report
        return false if @attempt >= @options[:try_count]

        @attempt += 1
        update_scan_options(failed_tests)
        retry
      rescue FastlaneCore::Interface::FastlaneBuildFailure => _
        return false if @attempt >= @options[:try_count]

        @attempt += 1
        retry
      end
    end

    def update_scan_config
      if !Scan.config[:output_types].include?('junit') && !parallel_running?
        output_types = Scan.config[:output_types].split(',')
        output_types << 'junit'
        Scan.config[:output_types] = output_types.join(',')
      end
      @options[:try_count] = 1 if @options[:try_count] < 1
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

    def print_parallel_scan_result(failed_tests_count: 0)
      return unless parallel_running?

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
      scan_options = @options.select { |key,  _|
        FastlaneScanHelper.valid_scan_keys.include?(key)
      }.merge(plugin_scan_options)
      scan_options[:only_testing] = failed_tests
      scan_options[:skip_build] = true
      scan_options[:test_without_building] = true
      scan_options[:build_for_testing] = false
      scan_options.delete(:skip_testing)
      Scan.cache.clear
      scan_options.each do |key, val|
        next if val.nil?

        Scan.config.set(key, val) unless val.nil?
        FastlaneCore::UI.verbose("\tSetting #{key.to_s} to #{val}")
      end
    end

    def plugin_scan_options
      xcargs = @options[:xcargs] || ''
      if xcargs&.include?('build-for-testing')
        FastlaneCore::UI.important(":xcargs, #{xcargs}, contained 'build-for-testing', removing it")
        xcargs.slice!('build-for-testing')
      end
      if xcargs.include?('-quiet')
        FastlaneCore::UI.important('Disabling -quiet as failing tests cannot be found with it enabled.')
        xcargs.gsub!('-quiet', '')
      end
      @options.select { |key, _| FastlaneScanHelper.valid_scan_keys.include?(key) }.merge({ xcargs: xcargs })
    end

    def extract_failed_tests
      if parallel_running?
        failed_tests_from_xcresult_report
      else
        failed_tests_from_junit_report
      end
    end

    def parallel_running?
      return @options[:concurrent_workers].to_i > 0 ||
            (@options[:devices] && @options[:devices].size > 1) ||
            (@options[:xcargs] && (@options[:xcargs] =~ /-parallel-testing-enabled(=|\s+)YES/ || @options[:xcargs].split('-destination').size > 2))
    end

    def failed_tests_from_junit_report
      report = junit_report
      suite_name = report.xpath('testsuites/@name').to_s.split('.')[0]
      test_cases = report.xpath('//testcase')
      only_testing = []
      test_cases.each do |test_case|
        next if test_case.xpath('failure').empty?

        test_class = test_case.xpath('@classname').to_s.split('.')[1]
        test_name = test_case.xpath('@name')
        only_testing << "#{suite_name}/#{test_class}/#{test_name}"
      end
      only_testing
    end

    def junit_report(cached: false)
      unless cached
        report_options = FastlaneScanHelper.report_options
        output_files = report_options.instance_variable_get(:@output_files)
        output_directory = report_options.instance_variable_get(:@output_directory)
        file_name = output_files.select { |name| name.include?('.xml') }.first
        @junit_report_path = "#{output_directory}/#{file_name}"
        @cached_junit_report = File.open(@junit_report_path) { |f| Nokogiri::XML(f) }
      end
      @cached_junit_report
    end

    def update_scan_junit_report
      return if @attempt == 1 || parallel_running?

      old_junit_report = junit_report(cached: true)
      new_junit_report = junit_report(cached: false)

      new_junit_report.css("testsuites").zip(old_junit_report.css("testsuites")).each do |new_suites, old_suites|
        old_suites.attributes["failures"].value = new_suites.attributes["failures"].value
        new_suites.css("testsuite").zip(old_suites.css("testsuite")).each do |new_suite, old_suite|
          old_suite.attributes["failures"].value = new_suite.attributes["failures"].value
        end
      end

      new_junit_report.css('testcase').each do |node1|
        old_junit_report.css('testcase').each do |node2|
          node2.children = node1.children if node1['name'] == node2['name']
        end
      end

      File.open(@junit_report_path, "w+") { |f| f.write(old_junit_report.to_xml) }
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
