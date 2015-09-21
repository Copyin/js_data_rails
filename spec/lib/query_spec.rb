describe JsDataRails::Query do
  subject { instance }

  let(:instance) do
    described_class.new(
      scope:    scope,
      params:   params,
      requires: requires,
      permits:  permits
    )
  end
  let(:scope)          { double(:scope) }
  let(:params)         { double(:action_controller_params, require: true) }
  let(:requires)       { [:user_id] }
  let(:permits)        { [] }
  let(:js_data_clause) { {user_id: {"==": 1}} }
  let(:processed_json) { JSON.generate(js_data_clause) }

  before(:each) do
    allow(params).to receive(:[]).with("where").and_return(processed_json)
  end

  describe "requiring and permitting properties" do
    describe "#permit_property" do
      let(:requires) { [] }

      context "with a permitted property in the parameters" do
        let(:permits) { [:user_id] }

        it "doesn't add any warnings" do
          expect(subject.warnings).to be_empty
        end

        it "doesn't add any errors" do
          expect(subject.errors).to be_empty
        end

        it "includes the property in what is passed to Clause" do
          expect(subject.properties).to eq(js_data_clause)
        end
      end

      context "with a property that has not been permitted" do
        let(:permits)        { [:user_id] } # To ensure we don't hit "Nothing permitted" errors
        let(:js_data_clause) { {blog_id: {"==": 42}, user_id: {"==": 1}} }

        it "adds a warning that the property is not permitted" do
          expect(subject.warnings).to include("Property 'blog_id' is not permitted")
        end

        it "doesn't add any errors" do
          expect(subject.errors).to be_empty
        end

        it "doesn't include the property in what is passed to the Clause" do
          expect(subject.properties).to eq(user_id: {"==": 1})
        end
      end

      context "with a mixture of permitted properties" do
        let(:permits) { [:user_id, :surname, :job_id] }
        let(:js_data_clause) { {
          user_id:  {"==": 1},
          forename: {"==": "bob"},
          blog_id:  {"==": 42},
          job_id:   {"in": [5,6,7]}
        } }

        it "adds warnings for unpermitted properties" do
          expect(subject.warnings).to include("Property 'forename' is not permitted")
          expect(subject.warnings).to include("Property 'blog_id' is not permitted")
        end

        it "doesn't add any errors" do
          # binding.pry
          expect(subject.errors).to be_empty
        end

        it "only includes the permitted properties in what is passed to the Clause" do
          expect(subject.properties).to eq(
            user_id: {"==": 1},
            job_id: {"in": [5,6,7]}
          )
        end
      end
    end

    describe "#require_property" do
      context "with a required property in the parameters" do
        it "doesn't add any warnings" do
          expect(subject.warnings).to be_empty
        end

        it "doesn't add any errors" do
          expect(subject.errors).to be_empty
        end

        it "includes the property in what is passed to Clause" do
          expect(subject.properties).to eq(js_data_clause)
        end
      end

      context "with a property that has not been required" do
        let(:permits)        { [:user_id] } # To ensure we don't hit "Nothing permitted" errors
        let(:js_data_clause) { {blog_id: {"==": 42}, user_id: {"==": 1}} }
        let(:requires)       { [] }

        it "adds a warning that the property is not permitted" do
          expect(subject.warnings).to include("Property 'blog_id' is not permitted")
        end

        it "doesn't add any errors" do
          expect(subject.errors).to be_empty
        end

        it "doesn't include the property in what is passed to the Clause" do
          expect(subject.properties).to eq(user_id: {"==": 1})
        end
      end

      context "when missing a required parameter" do
        let(:js_data_clause) { {} }

        it "doesn't add any warnings" do
          expect(subject.warnings).to be_empty
        end

        it "adds an error" do
          expect(subject.errors).to include("Missing required property 'user_id'")
        end

        it "doesn't include the property in what is passed to the Clause" do
          expect(subject.properties).to eq({})
        end
      end

      context "with a mixture of required properties" do
        let(:requires) { [:user_id, :surname, :job_id, :foo] }
        let(:js_data_clause) { {
          user_id:  {"==": 1},
          forename: {"==": "bob"},
          blog_id:  {"==": 42},
          job_id:   {"in": [5,6,7]}
        } }

        it "adds warnings for unrequired properties" do
          expect(subject.warnings).to include("Property 'forename' is not permitted")
          expect(subject.warnings).to include("Property 'blog_id' is not permitted")
        end

        it "adds errors for missing required properties" do
          expect(subject.errors).to include("Missing required property 'surname'")
          expect(subject.errors).to include("Missing required property 'foo'")
        end

        it "allows no properties to be passed to the Clause due to the error" do
          expect(subject.properties).to eq({})
        end
      end
    end

    context "with a mixture of required and permitted properties" do
      let(:permits) { [:bar, :baz] }
      let(:js_data_clause) { {
        user_id:  {"==": 1},
        forename: {"==": "bob"},
        blog_id:  {"==": 42},
        job_id:   {"in": [5,6,7]},
        baz:      {"==": "some value"},
        bored:    {"in": ["so", "many", "params"]}
      } }

      context "with missing requires" do
        let(:requires) { [:user_id, :surname, :job_id, :foo] }

        it "adds warnings for unpermitted properties" do
          expect(subject.warnings).to include("Property 'forename' is not permitted")
          expect(subject.warnings).to include("Property 'blog_id' is not permitted")
          expect(subject.warnings).to include("Property 'bored' is not permitted")
        end

        it "adds errors for the missing required properties" do
          expect(subject.errors).to include("Missing required property 'surname'")
          expect(subject.errors).to include("Missing required property 'foo'")
        end

        it "allows no properties to be passed to the Clause due to the error" do
          expect(subject.properties).to eq({})
        end
      end

      context "with no missing requires" do
        let(:requires) { [:user_id, :job_id] }

        it "adds warnings for unpermitted properties" do
          expect(subject.warnings).to include("Property 'forename' is not permitted")
          expect(subject.warnings).to include("Property 'blog_id' is not permitted")
          expect(subject.warnings).to include("Property 'bored' is not permitted")
        end

        it "adds no errors" do
          expect(subject.errors).to be_empty
        end

        it "correctly picks what properties to be passed to the Clause" do
          expect(subject.properties).to eq(
            user_id:  {"==": 1},
            baz:      {"==": "some value"},
            job_id:   {"in": [5,6,7]}
          )
        end
      end
    end
  end

  describe "#scope" do
    subject { instance.scope }

    context "with valid parameters" do
      before(:each) do
        allow(scope).to receive(:where).with(["user_id = ?", 1]).and_return([:model_1])
      end

      it "returns the filtered data" do
        expect(subject.first).to eq(:model_1)
      end

      context "when there is nothing permitted" do
        let(:requires) { [] }
        let(:permits)  { [] }

        it "includes an error" do
          expect(instance.errors).to include("Nothing has been permitted")
        end

        it "forces the scope to return nothing" do
          expect(scope).to receive(:where).with("1 = 0")
          subject
        end
      end
    end

    describe "handling invalid parameters" do
      context "when we don't have valid JSON" do
        let(:processed_json) { "Garbage" }

        it "includes an error" do
          expect(instance.errors).to include("'Garbage' must be valid js-data JSON")
        end

        it "forces the scope to return nothing" do
          expect(scope).to receive(:where).with("1 = 0")
          subject
        end
      end

      context "without JSON in a js-data format" do
        let(:js_data_clause) { [1,2,3] }

        it "includes an error" do
          expect(instance.errors).to include("'[1,2,3]' must be valid js-data JSON")
        end

        it "forces the scope to return nothing" do
          expect(scope).to receive(:where).with("1 = 0")
          subject
        end
      end

      context "when there are only invalid filter operations" do
        let(:js_data_clause) { {user_id: 1} } # Invalid as no hash provided

        it "includes an error" do
          expect(instance.errors).to include("Filter operation '1' for 'user_id' is not valid or not yet supported")
        end

        it "forces the scope to return nothing" do
          expect(scope).to receive(:where).with("1 = 0")
          subject
        end
      end

      context "when there is a mix of valid and invalid filter operations" do
        let(:js_data_clause) do
          {
            user_id: 1,                 # Invalid as no hash provided
            blog_id: {"==": 1, ">": 2}, # Invalid as only one operator allowed
            foo: {in: [1,2]}            # Valid filter operation
          }
        end

        it "includes an error" do
          expect(instance.errors).to include("Filter operation '1' for 'user_id' is not valid or not yet supported")
          expect(instance.errors).to include("Filter operation '{:===>1, :>=>2}' for 'blog_id' is not valid or not yet supported")
        end

        it "forces the scope to return nothing" do
          expect(scope).to receive(:where).with("1 = 0")
          subject
        end
      end
    end

    context "with an operator we don't have yet" do
      let(:js_data_clause) { {user_id: {">": 42}} }

      it "includes an error" do
        expect(instance.errors).to include("Filter operation '{:>=>42}' for 'user_id' is not valid or not yet supported")
      end

      it "forces the scope to return nothing" do
        expect(scope).to receive(:where).with("1 = 0")
        subject
      end
    end
  end
end
