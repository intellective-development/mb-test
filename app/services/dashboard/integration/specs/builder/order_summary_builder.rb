module Dashboard
  module Integration
    module Specs
      module Builder
        class OrderSummaryBuilder
          attr_reader :summary

          def self.build
            builder = new
            yield(builder)
            builder.summary
          end

          def initialize
            @summary = Dashboard::Integration::Specs::Models::OrderSummary.new
          end

          def set_tax_rate(tax_rate)
            @summary.tax_rate = tax_rate.to_f
          end

          def set_tax_total(tax_total)
            @summary.tax_total = tax_total.to_f
          end

          def set_total(total)
            @summary.total = total.to_f
          end

          def set_subtotal(subtotal)
            @summary.subtotal = subtotal.to_f
          end

          def set_fees_total(fees_total)
            @summary.fees_total = fees_total.to_f
          end
        end
      end
    end
  end
end
