# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 8.0 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `8.0`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
#
# Stock template for the 8.0 hop (fetched verbatim from the `railties-8.0.5`
# gem installed via Gemfile.next, roadmap Task 9 -- the terminal hop of the
# version-hop ladder, target_stack: Rails 8.0 / Ruby 3.3+). Audit results
# below; nothing flipped except where noted.

# `to_time` UTC-offset vs. full-timezone preservation.
# Not flipped to `:zone` (the new 8.0+/8.1 behavior) -- this app's one
# `.to_time` call site (`TasksController#update_status`,
# `params[:task][:completed_on].to_time`) is on a plain String, not a
# TimeWithZone/Time/DateTime instance, so this setting doesn't affect it
# either way (grepped app/ and lib/ for other `TimeWithZone#to_time`/
# `Time#to_time`/`DateTime#to_time` callers; none found). NOTE: Rails 8.0's
# `ActiveSupport.to_time_preserves_timezone=` unconditionally emits a
# deprecation warning for ANY value other than `:zone` (including this
# app's current implicit legacy default) -- this is Rails proactively
# warning about its OWN Rails 8.1 default flip, not something an app can
# silence without adopting the new semantics early. Confirmed benign (does
# not fail tests, matches Task 8/9's "pin old behavior unless forced"
# posture) and left as the harmless boot-time warning it is.
# Rails.application.config.active_support.to_time_preserves_timezone = :zone

# Consider only `If-None-Match` when both `If-Modified-Since` and
# `If-None-Match` are present (RFC 7232 Section 6 compliance).
# Not flipped -- no forcing function; this app doesn't rely on combined
# conditional-GET header semantics anywhere (grepped controllers for
# `stale?`/`fresh_when`; none found).
# Rails.application.config.action_dispatch.strict_freshness = true

# Set `Regexp.timeout` to 1s (ReDoS hardening).
# Not flipped -- this is a global Ruby-level `Regexp.timeout=` call (not
# scoped to Rails-internal regexes), and this app has user-facing regex
# usage in a few validations (e.g. email format) that were never audited
# against a 1s ceiling; a global timeout is good security hygiene but
# deserves its own deliberate review rather than a load_defaults side
# effect. Flagged as a recommended near-term follow-up (roadmap Task 11's
# dependency-modernization tail or a dedicated security pass), not bundled
# into this hop.
# Regexp.timeout = 1
