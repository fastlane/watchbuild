<h3 align="center">
  <a href="https://github.com/fastlane/fastlane/tree/master/fastlane">
    <img src=".assets/fastlane.png" width="150" />
    <br />
    fastlane
  </a>
</h3>

-------

WatchBuild
============

[![Twitter: @FastlaneTools](https://img.shields.io/badge/contact-@FastlaneTools-blue.svg?style=flat)](https://twitter.com/FastlaneTools)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/watchbuild/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/watchbuild.svg?style=flat)](http://rubygems.org/gems/watchbuild)

###### Get a notification once your App Store Connect build is finished processing

<img src=".assets/screenshot.png" width=350>

When you upload a new binary from Xcode to App Store Connect, you have to wait until it's done processing before you can submit it to the App Store.

As the [#iosprocessingtime](https://twitter.com/search?q=%23iosprocessingtime) varies from a few minutes to multiple hours, it's easy to forget to check App Store Connect to see if the build is ready. WatchBuild lets you know as soon as it is done.

WatchBuild is a simple standalone tool that shows a notification once your newly uploaded build was successfully processed by App Store Connect.

Once the build is ready to be pushed to TestFlight or for review, you get a macOS notification. You can even directly click on the notification to open the build on App Store Connect.

### Why use WatchBuild?

WatchBuild is a standalone tool and can be used without any of the other [fastlane tools](https://fastlane.tools). This is *big*, since you can use WatchBuild also if you use Xcode to upload your app.

This tool is not a replacement for [deliver](https://github.com/fastlane/fastlane/tree/master/deliver) (Upload metadata and builds to App Store Connect) or [pilot](https://github.com/fastlane/fastlane/tree/master/pilot) (Upload and distribute new builds to TestFlight), but is meant as a small helpful utility with the main purpose to wait for the binary processing to be finished.

Get in contact with the developer on Twitter: [@FastlaneTools](https://twitter.com/FastlaneTools)

-------
<p align="center">
    <a href="#installation">Installation</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#need-help">Need help?</a>
</p>

-------

# Installation

    sudo gem install watchbuild

Make sure, you have the latest version of the Xcode command line tools installed:

    xcode-select --install

# Usage

    watchbuild

You can pass your bundle identifier and username like this:

    watchbuild -a com.krausefx.app -u felix@krausefx.com

For a list of available parameters and commands run

    watchbuild --help

<img src=".assets/terminal.png">

## How is my password stored?

`WatchBuild` uses the secure [CredentialsManager](https://github.com/fastlane/fastlane/tree/master/credentials_manager) from [fastlane](https://fastlane.tools) that stores credentials in your local keychain.

# Need help?
Please submit an issue on GitHub and provide information about your setup

# Code of Conduct
Help us keep `watchbuild` open and inclusive. Please read and follow our [Code of Conduct](https://github.com/fastlane/fastlane/blob/master/CODE_OF_CONDUCT.md).

# License
This project is licensed under the terms of the MIT license. See the LICENSE file.

> This project and all fastlane tools are in no way affiliated with Apple Inc. This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs. All fastlane tools run on your own computer or server, so your credentials or other sensitive information will never leave your own computer. You are responsible for how you use fastlane tools.
