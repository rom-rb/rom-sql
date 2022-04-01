# frozen_string_literal: true

RSpec.describe "Plugins / :associates", seeds: false do
  include_context "relations"

  with_adapters do
    context "with Create command" do
      let(:users) { container.commands[:users] }
      let(:tasks) { container.commands[:tasks] }
      let(:tags) { container.commands[:tags] }

      before do
        conf.relation(:tasks) do
          schema(infer: true)

          associations do
            many_to_one :users, as: :user
            many_to_one :users, as: :other
            one_to_many :task_tags
            one_to_many :tags, through: :task_tags
          end
        end
      end

      describe "#with_association" do
        let(:user) do
          users[:create].call(name: "Jane")
        end

        let(:task) do
          {title: "Task one"}
        end

        before do
          conf.commands(:users) do
            define(:create) { config.result = :one }
          end

          conf.commands(:tasks) do
            define(:create) { config.result = :one }
          end
        end

        it "returns a command prepared for the given association" do
          command = tasks[:create].with_association(:user, key: %i[user_id id])

          expect(command.call(task, user))
            .to eql(id: 1, title: "Task one", user_id: user[:id])
        end

        it "allows passing a parent explicitly" do
          command = tasks[:create].with_association(:user, key: %i[user_id id], parent: user)

          expect(command.call(task))
            .to eql(id: 1, title: "Task one", user_id: user[:id])
        end

        it "allows setting up multiple associations" do
          command = tasks[:create]
            .with_association(:user, key: %i[user_id id], parent: user)
            .with_association(:other, key: %i[other_id id])

          expect(command.configured_associations).to eql(%i[user other])
        end
      end

      shared_context "automatic FK setting" do
        it "sets foreign key prior execution for many tuples" do
          create_user = users[:create].curry(name: "Jade")
          create_task = tasks[:create_many].curry([{title: "Task one"}, {title: "Task two"}])

          command = create_user >> create_task

          result = command.call

          expect(result).to match_array([
            {id: 1, user_id: 1, title: "Task one"},
            {id: 2, user_id: 1, title: "Task two"}
          ])
        end

        it "sets foreign key prior execution for one tuple" do
          create_user = users[:create].curry(name: "Jade")
          create_task = tasks[:create_one].curry(title: "Task one")

          command = create_user >> create_task

          result = command.call

          expect(result).to match_array(id: 1, user_id: 1, title: "Task one")
        end
      end

      context "with a schema" do
        include_context "automatic FK setting"

        before do
          conf.commands(:users) do
            define(:create) { config.result = :one }
          end

          conf.relation(:tasks) do
            schema(infer: true)

            associations do
              many_to_one :users, as: :user
              one_to_many :task_tags
              one_to_many :tags, through: :task_tags
            end
          end

          conf.commands(:tasks) do
            define(:create) do
              config.component.id = :create_many
              associates :user
            end

            define(:create) do
              config.component.id = :create_one
              config.result = :one
              associates :user
            end
          end
        end

        context "with many-to-many association" do
          before do
            conf.relation(:tags) do
              schema(infer: true)

              associations do
                one_to_many :task_tags
                one_to_many :tasks, through: :task_tags
              end
            end

            conf.relation(:task_tags) do
              schema do
                attribute :tag_id, ROM::SQL::Types::ForeignKey(:tags)
                attribute :task_id, ROM::SQL::Types::ForeignKey(:tasks)

                primary_key :tag_id, :task_id
              end

              associations do
                many_to_one :tags
                many_to_one :tasks
              end
            end

            conf.commands(:tasks) do
              define(:create) do
                config.result = :one
                associates :user
              end
            end

            conf.commands(:tags) do
              define(:create) do
                associates :tasks
              end
            end
          end

          it "sets FKs for the join table" do
            create_user = users[:create].curry(name: "Jade")
            create_task = tasks[:create].curry(title: "Jade's task")
            create_tags = tags[:create].curry([{name: "red"}, {name: "blue"}])

            command = create_user >> create_task >> create_tags

            result = command.call
            tags = relations[:tasks].associations[:tags].().to_a

            expect(result).to eql([
              {id: 1, task_id: 1, name: "red"}, {id: 2, task_id: 1, name: "blue"}
            ])

            expect(tags).to eql(result)
          end
        end
      end

      it "raises when already defined" do
        expect {
          conf.commands(:tasks) do
            define(:create) do
              config.result = :one
              associates :user, key: [:user_id, :id]
              associates :user, key: [:user_id, :id]
            end
          end
        }.to raise_error(ArgumentError, /user/)
      end
    end
  end

  with_adapters :sqlite do
    context "with Update command" do
      subject(:command) do
        container.commands[:tasks][:update].with_association(:user).new(tasks.by_pk(jane_task[:id]))
      end

      let(:john) do
        container.commands[:users][:create].call(name: "John")
      end

      let(:jane) do
        container.commands[:users][:create].call(name: "Jane")
      end

      let(:jane_task) do
        container.commands[:tasks][:create].call(user_id: jane[:id], title: "Jane Task")
      end

      let(:john_task) do
        container.commands[:tasks][:create].call(user_id: john[:id], title: "John Task")
      end

      before do
        conf.relation(:tasks) do
          schema(infer: true)

          associations do
            belongs_to :user
          end
        end

        conf.commands(:users) do
          define(:create) do
            config.result = :one
          end
        end

        conf.commands(:tasks) do
          define(:create) do
            config.result = :one
          end

          define(:update) do
            config.result = :one
          end
        end
      end

      it "automatically sets FK prior execution" do
        expect(command.curry(title: "Another John task").call(john))
          .to eql(id: jane_task[:id], user_id: john[:id], title: "Another John task")
      end
    end
  end
end
