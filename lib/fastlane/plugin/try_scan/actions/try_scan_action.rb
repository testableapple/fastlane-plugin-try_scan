module Fastlane
  module Actions

    require 'json'
    require 'fastlane/actions/scan'
    require_relative '../helper/scan_helper'
    require_relative '../helper/try_scan_runner'

    FastlaneScanHelper = TryScanManager::Helper::FastlaneScanHelper

    class TryScanAction < Action
      def self.run(params)
        if Helper.xcode_at_least?('11.0.0')
          params[:destination] = [params[:destination]] if params[:destination] && !params[:destination].kind_of?(Array)
          success = TryScanManager::Runner.new(params.values).run

          raise FastlaneCore::UI.test_failure!('Tests have failed') if params[:fail_build] && !success
        else
          raise FastlaneCore::UI.user_error!("Minimum supported Xcode: `v11.0.0` (used: `v#{Helper.xcode_version}`)")
        end
      end

      #####################################################
      #                   Documentation                   #
      #####################################################

      def self.description
        "Simple way to retry your scan action"
      end

      def self.authors
        ["Alexey Alter-Pesotskiy"]
      end

      def self.available_options
        ScanAction.available_options + [
          FastlaneCore::ConfigItem.new(
            key: :try_count,
            env_name: "FL_TRY_SCAN_TRY_COUNT",
            description: "Number of times to try to get your tests green",
            type: Integer,
            is_string: false,
            optional: true,
            default_value: 1
          ),
          FastlaneCore::ConfigItem.new(
            key: :try_parallel,
            env_name: "FL_TRY_SCAN_TRY_PARALLEL",
            description: "Should first run be executed in parallel? Equivalent to -parallel-testing-enabled",
            is_string: false,
            optional: true,
            default_value: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :retry_parallel,
            env_name: "FL_TRY_SCAN_RETRY_PARALLEL",
            description: "Should subsequent runs be executed in parallel? Required :try_parallel: true",
            is_string: false,
            optional: true,
            default_value: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :parallel_workers,
            env_name: "FL_TRY_SCAN_PARALLEL_WORKERS",
            description: "Specify the exact number of test runners that will be spawned during parallel testing. Equivalent to -parallel-testing-worker-count and :concurrent_workers",
            type: Integer,
            is_string: false,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :retry_strategy,
            env_name: "FL_TRY_SCAN_RETRY_STRATEGY",
            description: "What would you like to retry after failure: test, class or suite?",
            is_string: true,
            optional: true,
            default_value: 'test',
            verify_block: proc do |strategy|
              possible_strategies = ['test', 'class', 'suite']
              UI.user_error!("Error: :retry_strategy must equal to one of the following values: #{possible_strategies}") unless possible_strategies.include?(strategy)
            end
          )
        ]
      end

      def self.category
        :testing
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
