require 'spaceship'

module WatchBuild
  class Runner
    attr_accessor :spaceship

    # Uses the spaceship to create or download a provisioning profile
    # returns the path the newly created provisioning profile (in /tmp usually)
    def run
      FastlaneCore::PrintTable.print_values(config: WatchBuild.config,
                                            hide_keys: [],
                                            title: "Summary for WatchBuild #{WatchBuild::VERSION}")

      UI.message("Starting login with user '#{WatchBuild.config[:username]}'")

      ENV['FASTLANE_ITC_TEAM_ID'] = WatchBuild.config[:itc_team_id] if WatchBuild.config[:itc_team_id]
      ENV['FASTLANE_ITC_TEAM_NAME'] = WatchBuild.config[:itc_team_name] if WatchBuild.config[:itc_team_name]
      ENV['SLACK_URL'] = WatchBuild.config[:slack_url]

      Spaceship::Tunes.login(WatchBuild.config[:username], nil)
      Spaceship::Tunes.select_team
      UI.message('Successfully logged in')

      start = Time.now
      build = wait_for_build(start)
      minutes = ((Time.now - start) / 60).round
      notification(build, minutes)
    end

    def wait_for_build(start_time)
      UI.user_error!("Could not find app with app identifier #{WatchBuild.config[:app_identifier]}") unless app

      loop do
        begin
          build = find_build
          return build if build.processing == false

          seconds_elapsed = (Time.now - start_time).to_i.abs
          case seconds_elapsed
          when 0..59
            time_elapsed = Time.at(seconds_elapsed).utc.strftime '%S seconds'
          when 60..3599
            time_elapsed = Time.at(seconds_elapsed).utc.strftime '%M:%S minutes'
          else
            time_elapsed = Time.at(seconds_elapsed).utc.strftime '%H:%M:%S hours'
          end

          UI.message("Waiting #{time_elapsed} for iTunes Connect to process the build #{build.train_version} (#{build.build_version})... this might take a while...")
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
      require 'terminal-notifier'

      if build.nil?
        UI.message 'Application build is still processing'
        return
      end

      url = "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/ng/app/#{@app.apple_id}/activity/ios/builds/#{build.train_version}/#{build.build_version}/details"

      if !ENV['SLACK_URL'].empty?
        notify_slack(
          "App Store build #{build.train_version} (#{build.build_version}) has finished processing in #{minutes} minutes",
          ENV['SLACK_URL'])
      else
        TerminalNotifier.notify('Build finished processing',
                               title: build.app_name,
                               subtitle: "#{build.train_version} (#{build.build_version})",
                               execute: "open '#{url}'")
      end

      UI.success('Successfully finished processing the build')
      if minutes > 0 # it's 0 minutes if there was no new build uploaded
        UI.message('You can now tweet: ')
        UI.important("iTunes Connect #iosprocessingtime #{minutes} minutes")
      end
      UI.message(url)
    end

    private

    def app
      @app ||= Spaceship::Application.find(WatchBuild.config[:app_identifier])
    end

    def notify_slack(message, url)
      require 'net/http'
      require 'uri'
      require 'json'

      slack_url = uri = URI.parse(url)
      slack_message = {
        "text": message
      }

      header = {'Content-Type': 'application/json'}
  
      http = Net::HTTP.new(slack_url.host, slack_url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(slack_url.request_uri, header)
      request.body = slack_message.to_json
      response = http.request(request)

      if response.kind_of?(Net::HTTPSuccess)
        UI.success('Message sent to Slack.')
      else
        UI.user_error!('Error sending Slack notification.')
      end
    end

    def find_build
      build = nil
      app.latest_version.candidate_builds.each do |b|
        build = b if !build || b.upload_date > build.upload_date
      end

      unless build
        UI.user_error!("No processing builds available for app #{WatchBuild.config[:app_identifier]}")
      end

      build
    end
  end
end
