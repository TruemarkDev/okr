# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# Ruby 3.2 removed the deprecated `File.exists?` alias outright (roadmap
# Task 9's Ruby 3.1 -> 3.3 bump) -- use `File.exist?` instead; same check,
# no behavior change.
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
