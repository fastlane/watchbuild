require 'fastlane_core'
require 'credentials_manager'

module WatchBuild
  class Options
    def self.available_options
      user = CredentialsManager::AppfileConfig.try_fetch_value(:itunes_connect_id)
      user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

      [
        FastlaneCore::ConfigItem.new(key: :app_identifier,
                                     short_option: '-a',
                                     env_name: 'APP_IDENTIFIER',
                                     description: 'The bundle identifier of your app',
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)),
        FastlaneCore::ConfigItem.new(key: :username,
                                     short_option: '-u',
                                     env_name: 'FASTLANE_USER',
                                     description: 'Your Apple ID Username',
                                     code_gen_sensitive: true,
                                     default_value: user),
        FastlaneCore::ConfigItem.new(key: :itc_team_id,
                                     short_option: '-k',
                                     env_name: 'FASTLANE_ITC_TEAM_ID',
                                     description: "The ID of your App Store Connect team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :itc_team_name,
                                     short_option: '-p',
                                     env_name: 'FASTLANE_ITC_TEAM_NAME',
                                     description: "The name of your App Store Connect team if you're in multiple teams",
                                     optional: true,
                                     code_gen_sensitive: true,
                                     default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_name),
                                     default_value_dynamic: true),
        FastlaneCore::ConfigItem.new(key: :sample_only_once,
                                     description: 'Only check for the build once, instead of waiting for it to process',
                                     is_string: false,
                                     default_value: false),
        FastlaneCore::ConfigItem.new(key: :slack_url,
                                     short_option: '-n',
                                     env_name: 'SLACK_URL',
                                     description: 'Provide a slack webhook URL to notify a channel of a build',
                                     is_string: true,
                                     default_value: "")                             
      ]
    end
  end
end
