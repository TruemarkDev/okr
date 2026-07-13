# Foundation 5 (foundation-rails 5.2.1.0, unmaintained since ~2015) wraps
# every component's CSS -- grid, top-bar, dropdown, forms, buttons, tabs,
# panels, off-canvas, etc. -- in its own `exports()` mixin
# (foundation/_functions.scss):
#
#   @if (index($modules, $name) == false) { ... }
#
# That mixin was written for the Sass semantics current when Foundation
# shipped, where index() returned the boolean `false` for "not found". The
# `sass` gem now returns Sass null instead (the modern Sass spec), so
# `null == false` is always false and every exports() block -- i.e.
# effectively all of Foundation's real layout/grid/component CSS --
# silently renders nothing, even though the asset pipeline reports success.
# That is why the app renders unstyled/overlapping despite every asset
# request returning 200.
#
# Restoring the old "false for not found" behavior here -- rather than
# patching the vendored, unmaintained foundation-rails gem's scss, which
# can't reliably be shadowed anyway (its components re-`@import` their own
# functions.scss internally) and would be lost on every `bundle install` --
# is the smallest fix that makes Foundation 5's own scss work again on a
# modern Sass. Safe to delete once foundation-rails is upgraded/replaced.
Rails.application.config.after_initialize do
  require "sass"

  Sass::Script::Functions.module_eval do
    def index(list, value)
      idx = list.to_a.index { |e| e.eq(value).to_bool }
      idx ? number(idx + 1) : bool(false)
    end
  end
end
