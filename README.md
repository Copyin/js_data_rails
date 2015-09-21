[![Circle CI](https://circleci.com/gh/Twistilled/js_data_rails.svg?style=svg)](https://circleci.com/gh/Twistilled/js_data_rails)

# JsDataRails

This library allows you to take queries filtered from the awesome
[js-data](http://www.js-data.io) javascript library, and turn it into its
corresponding ActiveRecord format.

## Usage

The intended usage is to create a `JsDataRails::Query` object then iterate over
the results from that to perform some action.

``` ruby
results = JsDataRails::Query.new(
  scope:     active_record_scope,
  params:    controller_params,
  requires:  required_fields,
  permits:   permitted_fields
)

# To get an array of all results in JSON format
results.map {|r| r.to_json}

# To take some action over each result
results.each {|r| r.do_something_funky}

# Inspect any errors or warnings which prevented the query from running
results.errors   # => e.g. ["Missing required property 'user_id'"]
results.warnings # => e.g. ["Property 'blog_id' is not permitted"]
```

The fields are defined as follows:

* `active_record_scope`: This can be anything from your model layer with any
  Active Record chaining you want on top of it, for example `User` or
  `User.order(:score)`
* `controller_params`: These are the ActionController params from the request
  * **NOTE** Internally we call `params.require["where"]` to ensure we've
    actually got a js-data style query. Although this potentially should be
    called in the controller, we've pulled it out for DRYness as we were just
    doing this all the time.
* `required_fields`: Analogous to `#require` in strong params. If any of these
  fields are missing, then we will return 0 results and include a corresponding
  error in the `#errors` array. Note that this can happily be empty so long as
  there are permitted fields.
* `permitted_fields`: Analogous to `#permit` in strong params. If any of these
  fields are missing, no errors are thrown.

If nothing has been `permitted` or `required`, 0 rows will be returned and an
error will be added to the `#errors` array.

## Example

We might have some query from js-data in the format:

``` javascript
// Search for selected users who got full marks
User.filter({
  where: {
    userId: {
      in: [1,2,3]
    },
    score: {
      "==": 100
    }
  }
});
```
In our Rails controller, we could then simply do the following to get all
users:

``` ruby
class UsersController < ActionController::Base
  respond_to :json

  def index
    users = JsDataRails::Query.new(
      scope:    User,
      params:   params,
      requires: [:id],
      permits:  [:score]
    )

    render plain: JSON.generate(
      results:  { users.map {|u| u.to_json} },
      errors:   users.errors,
      warnings: users.warnings
    )
  end
end
```

The interface itself will handle filtering. The requires and permits are
analogous to those used by strong params.

## When something is unexpected

In the following scenarios, we will always return 0 rows:

1. If we get something coming through the controller which is not formatted
   correctly (i.e. probably hasn't come from js-data)
2. Missing required fields
3. Has no fields which have been permitted and no required fields are configured

We do this by calling `scope.where("1 = 0")`. This is because if we simply
don't filter the scope, we may end up running horrendous queries, and if we've
got something unexpected we simply don't want to do that.

For example, if we have the following scenario:

``` ruby
# Given params["where"] = '{"score": {"==": 500}}'
users = JsDataRails::Query.new(
  scope:    User.order(:created_at),
  params:   params,
  requires: [:user_id],
  permits:  [:score]
)

users.map {|u| u.to_json}
```

It's possible that the final line will end up calling this SQL query, if we
don't escape it somehow:

``` SQL
SELECT * FROM users WHERE score = 500 ORDER BY created_at DESC;
```

If we've got hundreds of thousands of users and haven't indexed our `score`
column (which isn't unreasonable given we expect to be filtering by `user_id`),
we'd end up with a query which hammers our database and brings down our site.

Instead, we'll run the following and end up with 0 rows and no load on our DB:

``` SQL
SELECT * FROM users WHERE score = 500 and 1 = 0 ORDER BY created_at DESC;
```

## TODO

* Handle more operators - currently only "==" and "in" are supported
* Also handle pagination and sorting options that come through from js-data

