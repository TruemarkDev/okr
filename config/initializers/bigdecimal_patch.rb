if defined?(BigDecimal) && BigDecimal.respond_to?(:new)
  # nothing needed, already works
elsif defined?(BigDecimal)
  class BigDecimal
    def self.new(*args)
      BigDecimal(*args)
    end
  end
end

