module Spree
  module Core
    module ControllerHelpers
      module Store
        extend ActiveSupport::Concern

        included do
          helper_method :supported_currencies
          helper_method :current_currency
          helper_method :current_store
          helper_method :current_price_options
          before_action :set_user_current_store
        end

        def current_currency
          if defined?(session) && session.key?(:currency) && supported_currencies.map(&:iso_code).include?(session[:currency])
            session[:currency]
          elsif params[:currency].present? && supported_currencies.map(&:iso_code).include?(params[:currency])
            params[:currency]
          else
            current_store.default_currency
          end
        end

        def supported_currencies
          current_store.supported_currencies_list
        end

        def current_store
          @current_store ||= Spree::Store.current(request.env['SERVER_NAME'])
        end

        def set_user_current_store
          return if try_spree_current_user.nil?

          try_spree_current_user.store = current_store
          try_spree_current_user.save
        end

        # Return a Hash of things that influence the prices displayed in your shop.
        #
        # By default, the only thing that influences prices that is the current order's +tax_zone+
        # (to facilitate differing prices depending on VAT rate for digital products in Europe, see
        # https://github.com/spree/spree/pull/6295 and https://github.com/spree/spree/pull/6662).
        #
        # If your prices depend on something else, overwrite this method and add
        # more key/value pairs to the Hash it returns.
        #
        # Be careful though to also patch the following parts of Spree accordingly:
        #
        # * `Spree::VatPriceCalculation#gross_amount`
        # * `Spree::LineItem#update_price`
        # * `Spree::Stock::Estimator#taxation_options_for`
        # * Subclass the `DefaultTax` calculator
        #
        def current_price_options
          {
            tax_zone: current_tax_zone
          }
        end

        private

        def current_tax_zone
          @current_tax_zone ||= @current_order&.tax_zone || Spree::Zone.default_tax
        end
      end
    end
  end
end
