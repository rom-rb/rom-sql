# frozen_string_literal: true

RSpec.describe "Commands / Postgres / Upsert", :postgres, seeds: false do
  subject(:command) { task_commands[:create_or_update] }

  include_context "relations"

  before do
    conn.execute "ALTER TABLE tasks add CONSTRAINT tasks_title_key UNIQUE (title)"

    conn[:users].insert id: 1, name: "Jane"
    conn[:users].insert id: 2, name: "Joe"
    conn[:users].insert id: 3, name: "Jean"
  end

  describe "#call" do
    let(:task) do
      {title: "task 1", user_id: 1}
    end

    let(:excluded) do
      task.merge(user_id: 3)
    end

    before do
      command_config = self.command_config

      conf.commands(:tasks) do
        define("Postgres::Upsert") do
          config.component.id = :create_or_update
          config.result = :one

          instance_exec(&command_config)
        end
      end
    end

    before do
      command.relation.upsert(task)
    end

    context "on conflict do nothing" do
      let(:command_config) { -> {} }

      it "returns nil" do
        expect(command.call(excluded)).to be nil
      end
    end

    context "on conflict do update" do
      context "with conflict target" do
        let(:command_config) do
          -> do
            config.conflict_target = :title
            config.update_statement = {user_id: 2}
          end
        end

        it "returns updated data" do
          expect(command.call(excluded)).to eql(id: 1, user_id: 2, title: "task 1")
        end

        context "with index predicate" do
          before do
            conn.execute <<~SQL
              ALTER TABLE tasks DROP CONSTRAINT tasks_title_key;

              CREATE UNIQUE INDEX tasks_title_partial_index ON tasks (title)
                            WHERE user_id = 1;
            SQL
          end

          let(:command_config) do
            -> do
              config.conflict_target = :title
              config.conflict_where = {user_id: 1}
              config.update_statement = {user_id: 2}
            end
          end

          context "when predicate matches" do
            let(:excluded) { task }

            it "returns updated data", :aggregate_failures do
              expect(command.call(excluded)).to eql(id: 1, user_id: 2, title: "task 1")
            end
          end

          context "when predicate does not match" do
            let(:excluded) { task.update(user_id: 2) }

            it "creates new task", :aggregate_failures do
              expect(command.call(excluded)).to eql(id: 2, user_id: 2, title: "task 1")
            end
          end
        end
      end

      context "with constraint name" do
        let(:command_config) do
          -> do
            config.constraint = :tasks_title_key
            config.update_statement = {user_id: Sequel.qualify(:excluded, :user_id)}
          end
        end

        it "returns updated data" do
          expect(command.call(excluded)).to eql(id: 1, user_id: 3, title: "task 1")
        end
      end

      context "with where clause" do
        let(:command_config) do
          -> do
            config.conflict_target = :title
            config.update_statement = {user_id: nil}
            config.update_where = {Sequel.qualify(:tasks, :id) => 2}
          end
        end

        it "returns nil" do
          expect(command.call(excluded)).to be nil
        end
      end
    end
  end
end
