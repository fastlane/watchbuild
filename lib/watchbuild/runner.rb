require 'spaceship'

module WatchBuild
  class Runner
    attr_accessor :spaceship

    # Uses the spaceship to create or download a provisioning profile
    # returns the path the newly created provisioning profile (in /tmp usually)
    def run
      FastlaneCore::PrintTable.print_values(config: WatchBuild.config,
                                            hide_keys: [:apple_key_id,:apple_issuer_id,:apple_keyfile_path],
                                            title: "Summary for WatchBuild #{WatchBuild::VERSION}")

      UI.message("Starting login with user '#{WatchBuild.config[:username]}'")

      ENV['FASTLANE_ITC_TEAM_ID'] = WatchBuild.config[:itc_team_id] if WatchBuild.config[:itc_team_id]
      ENV['FASTLANE_ITC_TEAM_NAME'] = WatchBuild.config[:itc_team_name] if WatchBuild.config[:itc_team_name]
      ENV['SLACK_URL'] = WatchBuild.config[:slack_url]

      Spaceship::ConnectAPI.auth(key_id: WatchBuild.config[:apple_key_id], issuer_id: WatchBuild.config[:apple_issuer_id], filepath: WatchBuild.config[:apple_keyfile_path], key: nil, duration: nil, in_house: nil)
      UI.message('Successfully logged in')

      start = Time.now
      build = wait_for_build(start)
      minutes = ((Time.now - start) / 60).round
      notification(build, minutes)
    end

    def wait_for_build(start_time)
      UI.user_error!("Could not find app with app identifier #{WatchBuild.config[:app_identifier]}") unless app

      build = nil
      showed_info = false

      loop do
        begin
          build = find_build(build)

          if build.nil?
            UI.important("Read more information on why this build isn't showing up yet - https://github.com/fastlane/fastlane/issues/14997") unless showed_info
            showed_info = true
          else
            return build if build.processed?

            seconds_elapsed = (Time.now - start_time).to_i.abs
            case seconds_elapsed
            when 0..59
              time_elapsed = Time.at(seconds_elapsed).utc.strftime '%S seconds'
            when 60..3599
              time_elapsed = Time.at(seconds_elapsed).utc.strftime '%M:%S minutes'
            else
              time_elapsed = Time.at(seconds_elapsed).utc.strftime '%H:%M:%S hours'
            end

            UI.message("Waiting #{time_elapsed} for App Store Connect to process the build #{build.app_version} (#{build.version})... this might take a while...")
          end
        rescue => ex
          UI.error(ex)
          UI.message('Something failed... trying again to recover')
        end
        if WatchBuild.config[:sample_only_once] == false
          sleep 30
        else
          break
        end
      end
      nil
    end

    def notification(build, minutes)
      if build.nil?
        UI.message 'Application build is still processing'
        return
      end

      platform = build.pre_release_version.platform.downcase.gsub('_', '')

      url = "https://appstoreconnect.apple.com/apps/#{app.id}/testflight/#{platform}/#{build.id}/metadata"

      slack_url = ENV['SLACK_URL'].to_s
      if !slack_url.empty?
        notify_slack(build, minutes, slack_url)
      else
        notify_terminal(build, minutes, url)
      end

      UI.success('Successfully finished processing the build')
      if minutes > 0 # it's 0 minutes if there was no new build uploaded
        UI.message('You can now tweet: ')
        UI.important("App Store Connect #iosprocessingtime #{minutes} minutes")
      end
      UI.message(url)
    end

    private

    def app
      @app ||= Spaceship::ConnectAPI::App.find(WatchBuild.config[:app_identifier])
    end

    def notify_slack(build, minutes, url)
      require 'net/http'
      require 'uri'
      require 'json'

      message = "App Store build #{build.app_version} (#{build.version}) has finished processing in #{minutes} minutes"
      slack_url = URI.parse(url)
      slack_message = {
        "text": message
      }

      header = {'Content-Type': 'application/json'}

      http = Net::HTTP.new(slack_url.host, slack_url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(slack_url.request_uri, header)
      request.body = slack_message.to_json
      response = http.request(request)

      if response.kind_of?(Net::HTTPSuccess)
        UI.success('Message sent to Slack.')
      else
        UI.user_error!('Error sending Slack notification.')
      end
    end

    def notify_terminal(build, minutes, url)
    	require 'terminal-notifier'

    	TerminalNotifier.notify('Build finished processing',
                              title: app.name,
                              subtitle: "#{build.app_version} (#{build.version})",
                              execute: "open '#{url}'")
    end

    # Finds a build if none given
    # Otherwise fetches a build (to get updated state)
    def find_build(build)
      if build.nil?
        builds = app.get_builds(includes: Spaceship::ConnectAPI::Build::ESSENTIAL_INCLUDES).select do |build|
          build.processing_state == Spaceship::ConnectAPI::Build::ProcessingState::PROCESSING
        end

        # Filter specific app_verison if specified
        if (app_version = WatchBuild.config[:app_version])
          builds = builds.select do |build|
            build.app_version.to_s == app_version.to_s
          end
        end

        # Filter specific app_build_number if specified
        if (app_build_number = WatchBuild.config[:app_build_number])
          builds = builds.select do |build|
            build.version.to_s == app_build_number.to_s
          end
        end

        build = builds.sort_by(&:uploaded_date).last
      else
        build = Spaceship::ConnectAPI::Build.get(build_id: build.id, includes: Spaceship::ConnectAPI::Build::ESSENTIAL_INCLUDES)
      end

      unless build
        UI.error("No processing builds available for app #{WatchBuild.config[:app_identifier]} - this may take a few minutes (check your email for processing issues if this continues)")
      end

      build
    end
  end
end
