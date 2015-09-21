# We currently only accept two types of query:
#
#     "property": { "==": value}
#     "property": { "in": [value1, value2, ...]}
#
# We do however accept these queries in combination. The inbound format of
# the js_data_query can therefore be:
#
#     {
#       "article_id": {"==": 42},
#       "commenter_surname": {"in": ["Smith", "Jones"]}
#     }
#
# Our nomenclature for this inbound data is
#
#   user_id:    {"==":     42 }
#     ||          ||       ||
#   property   operator   value
#            |------------------|
#                     ||
#              filter_operation
#
module JsDataRails
  module Clause
    extend self

    # In some instances, we have encountered some error, meaning the query
    # that's come through from js-data is not in a correct format.
    #
    # Consequently, we don't know what to do with this so we include a filter
    # which will cause any scope to return 0 rows to avoid running unexpected
    # large queries.
    #
    def select_nothing_clause
      "1 = 0"
    end

    def active_record_where_clause(js_data_clause:)
      # This error is essential, because otherwise we could be running a
      # completely unfiltered query which just selects * from some massive table
      return select_nothing_clause if js_data_clause_empty?(js_data_clause)

      statement = ""
      values = []
      js_data_clause.each do |property, filter_operation|
        operator = filter_operation.keys.first

        begin
          statement = append_active_record_clause_to(statement, property, operator)
          values << filter_operation[operator]
        rescue UnknownOperator
          # Just skip it
          next
        end
      end

      if statement == "" || values.empty?
        # In this case we've got nothing to query, so make sure we don't do
        # anything with it!
        select_nothing_clause
      else
        [statement] + values
      end
    end

    private

      def append_active_record_clause_to(statement, property, operator)
        clause = active_record_clause_for(property, operator)
        statement += (statement == "") ? clause : " AND #{clause}"
      end

      def active_record_clause_for(property, operator)
        case operator
        when :==
          "#{property} = ?"
        when :in
          "#{property} in (?)"
        else
          # NOTE: We should never hit this operator, as all input for this class
          # should have been validated by the Query prior to being passed on,
          # this is purely for safety
          raise UnknownOperator.new("Operator '#{operator}' not recognised")
        end
      end

      def js_data_clause_empty?(js_data_clause)
        js_data_clause.nil? || js_data_clause.empty?
      end
    end

end
