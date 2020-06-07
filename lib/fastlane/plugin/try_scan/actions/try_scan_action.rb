module Fastlane
  module Actions

    require 'fastlane/actions/scan'
    require_relative '../helper/scan_helper'
    require_relative '../helper/try_scan_runner'

    FastlaneScanHelper = TryScanManager::Helper::FastlaneScanHelper

    class TryScanAction < Action
      def self.run(params)
        prepare_for_testing(params)
        success = TryScanManager::Runner.new(params.values).run

        raise FastlaneCore::UI.test_failure!('Tests have failed') if params[:fail_build] && !success
      end

      def self.prepare_for_testing(params)
        warn_of_xcode11_result_bundle_incompatability(params)
        use_scanfile_to_override_settings(params.values)
        turn_off_concurrent_workers(params.values)
        prepare_scan_config(params.values)
        coerce_destination_to_array(params)
      end

      def self.warn_of_xcode11_result_bundle_incompatability(params)
        if FastlaneCore::Helper.xcode_at_least?('11.0.0')
          if params[:result_bundle]
            FastlaneCore::UI.important('As of Xcode 11, test_result bundles created in the output directory are actually symbolic links to an xcresult bundle')
          end
        elsif params[:output_types]&.include?('xcresult')
          FastlaneCore::UI.important("The 'xcresult' :output_type is only supported for Xcode 11 and greater. You are using #{FastlaneCore::Helper.xcode_version}.")
        end
      end

      def self.coerce_destination_to_array(params)
        destination = params[:destination] || Scan.config[:destination] || []
        unless destination.kind_of?(Array)
          params[:destination] = Scan.config[:destination] = [destination]
        end
      end

      def self.turn_off_concurrent_workers(scan_options)
        if Gem::Version.new(Fastlane::VERSION) >= Gem::Version.new('2.142.0')
          scan_options.delete(:concurrent_workers) if scan_options[:concurrent_workers].to_i > 0
        end
      end

      def self.use_scanfile_to_override_settings(scan_options)
        overridden_options = FastlaneScanHelper.options_from_configuration_file(
          FastlaneScanHelper.scan_options_from_try_scan_options(scan_options)
        )

        unless overridden_options.empty?
          FastlaneCore::UI.important("Scanfile found: overriding try_scan options with it's values.")
          overridden_options.each { |key, val| scan_options[key] = val }
        end
      end

      def self.prepare_scan_config(scan_options)
        Scan.config ||= FastlaneCore::Configuration.create(
          Fastlane::Actions::ScanAction.available_options,
          FastlaneScanHelper.scan_options_from_try_scan_options(scan_options)
        )
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

      def self.scan_options
        ScanAction.available_options.reject { |config| %i[output_types].include?(config.key) }
      end

      def self.available_options
        scan_options = ScanAction.available_options.reject { |config| %i[output_types].include?(config.key) }
        scan_options + [
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
