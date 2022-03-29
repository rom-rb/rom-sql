RSpec.describe "Commands / Delete" do
  include_context "users and tasks"

  let(:delete_user) { user_commands[:delete] }

  with_adapters do
    before do
      conf.relation(:users) do
        schema(infer: true)

        def by_name(name)
          where(name: name)
        end
      end

      conf.commands(:users) do
        define(:delete) do
          config.result = :one
        end
      end

      users.insert(id: 3, name: "Jade")
      users.insert(id: 4, name: "John")
    end

    describe "#transaction" do
      it "deletes in normal way if no error raised" do
        expect {
          users.transaction do
            users.by_name("Jade").command(:delete).call
          end
        }.to change { users.count }.by(-1)
      end

      it "deletes nothing if error was raised" do
        expect {
          users.transaction { |t|
            users.by_name("Jade").command(:delete).call
            t.rollback!
          }
        }.to_not change { users.count }
      end
    end

    describe "#call" do
      it "deletes all tuples in a restricted relation" do
        result = users.by_name("Jade").command(:delete).call

        expect(result).to eql(id: 3, name: "Jade")
      end

      it "re-raises database error" do
        command = users.by_name("Jade").command(:delete)

        expect(command.relation).to receive(:delete).and_raise(
          Sequel::DatabaseError, "totally wrong"
        )

        expect {
          command.call
        }.to raise_error(ROM::SQL::DatabaseError, /totally wrong/)
      end
    end

    describe "#execute" do
      context "with a single record" do
        it "materializes the result" do
          result = users.by_name(%w[Jade]).command(:delete).execute

          expect(result).to eq([{id: 3, name: "Jade"}])
        end
      end

      context "with multiple records" do
        it "materializes the results" do
          result = users.by_name(%w[Jade John]).command(:delete).execute

          expect(result).to eq([{id: 3, name: "Jade"}, {id: 4, name: "John"}])
        end
      end
    end
  end
end
