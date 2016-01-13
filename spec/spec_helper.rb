require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'webmock/rspec'
require 'vcr'
require 'pry'
require 'em-http'

Bundler.setup

require 'coinbase/exchange'

MARKET_REFS   = [ :currencies,
                  :products,
                  :orderbook,
                  :last_trade,
                  :trade_history,
                  :price_history,
                  :daily_stats ]

ACCOUNT_REFS  = [ :accounts,
                  :account,
                  :account_history,
                  :account_holds ]

ORDER_REFS    = [ :bid,
                  :ask,
                  :cancel,
                  :orders,
                  :order,
                  :fills ]

TRANSFER_REFS = [ :deposit,
                  :withdraw ]

def endpoints
  (MARKET_REFS << ACCOUNT_REFS << ORDER_REFS << TRANSFER_REFS).flatten!
end

def mock_item
  { 'id' => 'test', 'status' => 'OK' }
end

def mock_collection
  [ mock_item, mock_item ]
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end
