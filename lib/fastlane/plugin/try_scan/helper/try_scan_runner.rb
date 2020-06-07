module TryScanManager
  class Runner

    FastlaneScanHelper = TryScanManager::Helper::FastlaneScanHelper

    def initialize(options = {})
      @options = options
      warn_of_try_scan_option
    end

    def run
      update_scan_config
      print_summary
      attempt = 1
      begin
        warn_of_performing_attempts(attempt)
        clear_preexisting_data
        Scan::Runner.new.run
        return true
      rescue FastlaneCore::Interface::FastlaneBuildFailure, FastlaneCore::Interface::FastlaneTestFailure => _
        merge_junit_reports if attempt != 1
        return false if attempt > @options[:try_count]

        attempt += 1
        update_scan_options
        retry
      end
    end

    def update_scan_config
      Scan.config[:output_types] << 'junit' unless Scan.config[:output_types].include?('junit')
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

    def warn_of_performing_attempts(attempt)
      FastlaneCore::UI.important("TryScan shot №#{attempt}\n")
    end

    def warn_of_try_scan_option
      if @options[:try_count] <= 0
        FastlaneCore::UI.important(":try_count can't be less than or equal to zero. Setting a default value equal to `1`")
        @options[:try_count] = 1
      end
    end

    def clear_preexisting_data
      FastlaneScanHelper.remove_preexisting_simulator_logs(@options)
      FastlaneScanHelper.remove_preexisting_test_result_bundles(@options)
      FastlaneScanHelper.remove_preexisting_xcresult_bundles(@options)
      FastlaneScanHelper.remove_report_files
    end

    def update_scan_options
      scan_options = @options.select { |key,  _| FastlaneScanHelper.valid_scan_keys.include?(key) }.merge(plugin_scan_options)
      scan_options[:only_testing] = extract_failed_tests
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
      xcargs.gsub!(/-parallel-testing-enabled(=|\s+)(YES|NO)/, '')
      @options.select { |k,v| FastlaneScanHelper.valid_scan_keys.include?(k) }.merge({ xcargs: "#{xcargs} -parallel-testing-enabled NO " })
    end

    def extract_failed_tests
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

    def merge_junit_reports
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
  end
end
