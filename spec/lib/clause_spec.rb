describe JsDataRails::Clause do

  describe "#active_record_where_clause" do
    subject { described_class.active_record_where_clause(js_data_clause: js_data_clause) }

    context "with no arguments" do
      let(:js_data_clause) { {} }

      it "returns a clause guaranteed to return 0 rows" do
        expect(subject).to eq("1 = 0")
      end
    end

    context "with an '==' operator" do
      let(:js_data_clause) { {foo: {"==": "bar"}} }

      it "translates it into an AR friendly pair of arguments" do
        expect(subject).to eq(["foo = ?", "bar"])
      end
    end

    context "with an 'in' operator" do
      let(:js_data_clause) { {foo: {in: [1,2,3]}} }

      it "translates this into an AR friendly pair of arguments" do
        expect(subject).to eq(["foo in (?)", [1,2,3]])
      end
    end

    describe "unknown operators" do
      context "when it is the only filter operation" do
        let(:js_data_clause) { {foo: {not_an_operator: "bar"}} }

        it "selects no rows" do
          expect(subject).to eq("1 = 0")
        end
      end

      context "when some of the filter operations user unknown operators" do
        let(:js_data_clause) do
          {
            foo: {not_an_operator: [1,2,3]},
            bar: {in: [4,5,6]}
          }
        end

        it "discards the unkown operators" do
          expect(subject).to eq(["bar in (?)", [4,5,6]])
        end
      end
    end

    context "with multiple clauses" do
      let(:js_data_clause) do
        {
          foo:    {"==": "bar"},
          baz:    {"==": "zab"},
          blah:   {in:   [1, 2, 3]},
          boogie: {in:   ["the", "hip", "hop"]}
        }
      end

      it "translates these into AR friendly arguments" do
        expect(subject).to eq([
          "foo = ? AND baz = ? AND blah in (?) AND boogie in (?)",
          "bar",
          "zab",
          [1,2,3],
          ["the", "hip", "hop"]
        ])
      end
    end
  end
end
