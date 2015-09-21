require "js_data_rails/query"
require "js_data_rails/clause"

# Purely for #deep_symbolize_keys
require "active_support/core_ext/hash"

module JsDataRails
  class UnknownOperator < Exception; end

  SUPPORTED_OPERATORS = [:==, :in]
end
