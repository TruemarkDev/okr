# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.2 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.2`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
#
# Stock template for the 7.2 hop (fetched verbatim from the `railties-8.0.5`
# gem installed via Gemfile.next for this combined 7.1 -> 7.2 -> 8.0 hop,
# roadmap Task 9). Audit results below; nothing flipped except where noted.

# Defer Active Job's `#perform_later` enqueuing until after the current
# Active Record transaction commits.
# N/A -- this app has no ActiveJob-backed background job usage (confirmed
# again this hop via grep, same finding as every prior hop back to Task 6).
# Rails.application.config.active_job.enqueue_after_transaction_commit = :default

# Add image/webp to Active Storage's recognized image content types.
# N/A -- this app doesn't use Active Storage (CarrierWave/MiniMagick handle
# uploads; confirmed again this hop, same as every prior hop back to 5.2).
# Rails.application.config.active_storage.web_image_content_types = %w[...]

# Validate migration timestamps aren't forward-dated by more than a day.
# Not flipped -- this app's 35 migrations predate Rails 5's `[4.1]` version
# tagging (per the roadmap's own risk-hotspots note) and were generated over
# a multi-year span; enabling strict timestamp validation now risks
# surfacing pre-existing timestamp irregularities unrelated to this hop.
# `strong_migrations` isn't present in this repo either (noted in
# CLAUDE.md), so there's no existing migration-lint gate this toggle would
# complement. Deferred.
# Rails.application.config.active_record.validate_migration_timestamps = true

# PostgreSQL adapter automatic date decoding for manual queries.
# N/A -- this app uses mysql2, not pg (unchanged since the project's
# original 2016 Gemfile).
# Rails.application.config.active_record.postgresql_adapter_decode_dates = true

# Enable YJIT (Ruby 3.3+ performance optimization).
# FLIPPED ON this hop: this app's Ruby floor is now 3.3.11 (this hop's own
# Ruby 3.1 -> 3.3 bump), which is exactly the version YJIT graduated to
# stable/default-recommended in upstream Ruby. This is a pure interpreter
# performance optimization (no observable behavior change to audit -- YJIT
# is a JIT compiler, not a semantic change) and this app's Docker container
# isn't a documented memory-constrained deployment target, so there's no
# reason to leave the free performance on the table.
Rails.application.config.yjit = true
