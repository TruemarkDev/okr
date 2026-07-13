require 'test_helper'
require Rails.root.join('lib', 'omniauth', 'strategies', 'fluxapp')

# Characterization test for the custom fluxapp OmniAuth strategy
# (`lib/omniauth/strategies/fluxapp.rb`). The strategy runs in the OmniAuth
# request/callback middleware, so the controller test can't reach it — this
# pins its identity mapping directly: `uid` comes from raw_info["id"], and
# `info` projects email / name / nickname out of raw_info. `raw_info` itself
# just parses `access_token.get('/api/v1/me.json')`, so it is stubbed here to
# keep the test to the strategy's own mapping logic (no live HTTP).
class FluxappStrategyTest < ActiveSupport::TestCase
  def build_strategy(raw)
    strategy = OmniAuth::Strategies::Fluxapp.new(->(_env) { [200, {}, ['']] })
    strategy.define_singleton_method(:raw_info) { raw }
    strategy
  end

  test "uid is taken from raw_info id" do
    strategy = build_strategy('id' => '4242', 'email' => 'e@x.test')
    assert_equal '4242', strategy.uid
  end

  test "info maps email, name and nickname from raw_info" do
    strategy = build_strategy(
      'id' => '1', 'email' => 'flux@x.test', 'name' => 'Flux User', 'nickname' => 'flux'
    )

    info = strategy.info

    assert_equal 'flux@x.test', info[:email]
    assert_equal 'Flux User', info[:name]
    assert_equal 'flux', info[:nickname]
  end

  test "strategy is registered under the :fluxapp name" do
    strategy = build_strategy({})
    assert_equal :fluxapp, strategy.options.name
  end
end
