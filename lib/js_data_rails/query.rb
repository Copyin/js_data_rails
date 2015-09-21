module JsDataRails
  class Query
    include Enumerable

    attr_reader :errors, :warnings

    def initialize(scope:, params:, requires: [], permits: [])
      @scope        = scope
      @errors       = []
      @warnings     = []
      @properties   = {}

      # It could be worth leaving this require and parsing in the controllers,
      # but it's slightly DRYer having it here
      params.require("where")
      js_data_clause = params["where"] || "{}"

      begin
        parsed_js_data_clause = JSON.parse(js_data_clause).deep_symbolize_keys
      rescue
        @errors << "'#{js_data_clause}' must be valid js-data JSON"
        parsed_js_data_clause = {}
      end

      # Validate input, adding errors if we've been JSON which isn't in a
      # js-data query DSL format
      @js_data_clause = validate_input_clause(parsed_js_data_clause)

      require(*requires)
      permit(*permits)

      # Add warnings for unpermitted properties
      @js_data_clause.keys.each do |property|
        @warnings << "Property '#{property}' is not permitted" unless @properties.keys.include?(property)
      end

      @errors << "Nothing has been permitted" if nothing_permitted?
    end

    def require(*required_properties)
      required_properties.each do |property|
        if @js_data_clause.keys.include?(property)
          permit(property)
        else
          @errors << "Missing required property '#{property}'"
        end
      end
    end

    def permit(*permitted_properties)
      permitted_properties.each do |property|
        @properties[property] = @js_data_clause[property] unless @js_data_clause[property].nil?
      end
    end

    def properties
      @errors.any? ? {} : @properties
    end

    def scope
      return @scope.where(Clause.select_nothing_clause) if @errors.any?

      @scope.where(where_clause)
    end

    def each(&block)
      scope.each(&block)
    end

    private

      def where_clause
        Clause.active_record_where_clause(js_data_clause: properties)
      end

      def nothing_permitted?
        @properties.empty?
      end

      def validate_input_clause(js_data_clause)
        js_data_clause.inject({}) do |validated, (property, filter_operation)|
          if valid_operation?(filter_operation)
            validated[property] = filter_operation
          else
            @errors << "Filter operation '#{filter_operation}' for '#{property}' is not valid or not yet supported"
          end

          validated
        end
      end

      def valid_operation?(filter_operation)
        return false unless filter_operation.is_a?(Hash)
        # REVIEW: Is this valid? What about this case, is it valid in js-data?
        #   {"count": {">": 10, "<": 100}}
        return false if filter_operation.keys.count != 1

        SUPPORTED_OPERATORS.include?(filter_operation.keys.first)
      end
  end
end
