# frozen_string_literal: true

module Bitfinex
  # RESTv1 API historical data methods
  module RESTv1HistoricalData
    # View all of your balance ledger entries.
    #
    # @param currency [string] (optional) Specify the currency, default "USD"
    # @param params [Hash]
    # @option params [time?] :since
    # @option params [time?] :until
    # @option params [int?] :limit
    # @option params [string] :wallet
    # @return [Array]
    # @example:
    #   client.history
    def history(currency = 'usd', params = {})
      check_params(params, %i[since until limit wallet])
      params.merge!({ currency: currency })
      authenticated_post('history', params: params).body
    end

    # View your past deposits/withdrawals.
    #
    # @param currency [string] (optional) Specify the currency, default "USD"
    # @param params [Hash]
    # @option params [String] :method
    # @option params [time?] :since
    # @option params [time?] :until
    # @option params [Number?] :limit
    # @return [Array]
    # @example:
    #   client.movements
    def movements(currency = 'usd', params = {})
      check_params(params, %i[
                     method since until limit since_movement until_movement
                   ])

      params.merge!({ currency: currency })
      authenticated_post('history/movements', params: params).body
    end

    # View your past trades.
    #
    # @param symbol The pair traded (BTCUSD, LTCUSD, LTCBTC)
    # @param params [Hash]
    # @option params [time?] :until
    # @option params [time?] :timestamp
    # @option params [time?] :until
    # @option params [int?] :limit_trades default 50
    # @option params [int?] :reverse return trades in reverse order
    # @return [Array]
    # @example:
    #   client.mytrades
    def mytrades(symbol, params = {})
      check_params(params, %i[until limit_trades reverse timestamp])
      params.merge!({ symbol: symbol })
      authenticated_post('mytrades', params: params).body
    end
  end
end
