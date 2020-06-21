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
          prepare_scan_config(params.values)
          prepare_destination(params)
          success = TryScanManager::Runner.new(params.values).run

          raise FastlaneCore::UI.test_failure!('Tests have failed') if params[:fail_build] && !success
        else
          raise FastlaneCore::UI.user_error!("Minimum supported Xcode: `v11.0.0` (used: `v#{Helper.xcode_version}`)")
        end
      end

      def self.prepare_scan_config(scan_options)
        Scan.config = FastlaneCore::Configuration.create(
          Fastlane::Actions::ScanAction.available_options,
          FastlaneScanHelper.scan_options_from_try_scan_options(scan_options)
        )
      end

      def self.prepare_destination(params)
        destination = params[:destination] || Scan.config[:destination] || []
        unless destination.kind_of?(Array)
          params[:destination] = Scan.config[:destination] = [destination]
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
            description: "The number of times to retry running tests via scan",
            type: Integer,
            is_string: false,
            default_value: 1
          )
        ]
      end

      def self.category
        :testing
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end
