# frozen_string_literal: true

require 'spec_helper'

namespace :db do
  task :setup do
    # noop
  end
end

RSpec.describe 'MigrationTasks', :postgres, skip_tables: true do
  include_context 'database setup'

  let(:migrator) { container.gateways[:default].migrator }
  let(:task) { nil }

  before do
    ROM::SQL::Gateway.instance = nil
    ROM::SQL::RakeSupport.env = nil
    ROM::SQL::RakeSupport.migration_options = {}
    conf
  end

  after(:each) do
    task.reenable
  end

  context 'db:reset' do
    let(:task) { Rake::Task['db:reset'] }

    it 'calls proper commands' do
      expect(migrator).to receive(:run).with({ target: 0 })
      expect(migrator).to receive(:run)

      expect {
        task.invoke
      }.to output("<= db:reset executed\n").to_stdout
    end

    context 'with custom migration_options' do
      before do
        ROM::SQL::RakeSupport.migration_options = { table: :custom_table, column: :custom_column }
      end

      it 'calls proper commands' do
        expect(migrator).to receive(:run).with({ target: 0, table: :custom_table, column: :custom_column })
        expect(migrator).to receive(:run).with({ table: :custom_table, column: :custom_column })

        expect {
          task.invoke
        }.to output("<= db:reset executed\n").to_stdout
      end
    end
  end

  context 'db:migrate' do
    let(:task) { Rake::Task['db:migrate'] }

    context 'with VERSION' do
      it 'calls proper commands' do
        expect(migrator).to receive(:run).with({ target: 1 })

        expect {
          task.invoke(1)
        }.to output("<= db:migrate version=[1] executed\n").to_stdout
      end
    end

    context 'without VERSION' do
      it 'calls proper commands' do
        expect(migrator).to receive(:run)

        expect {
          task.execute
        }.to output("<= db:migrate executed\n").to_stdout
      end
    end

    it 'raises an error on missing both env and Gateway.instance' do
      ROM::SQL::RakeSupport.env = nil
      ROM::SQL::Gateway.instance = nil

      expect {
        task.execute
      }.to raise_error(ROM::SQL::RakeSupport::MissingEnv)
    end

    context 'with custom migration_options' do
      before do
        ROM::SQL::RakeSupport.migration_options = { table: :custom_table, column: :custom_column }
      end

      it 'calls proper commands' do
        expect(migrator).to receive(:run).with({ table: :custom_table, column: :custom_column })

        expect {
          task.invoke
        }.to output("<= db:migrate executed\n").to_stdout
      end
    end
  end

  context 'db:clean' do
    let(:task) { Rake::Task['db:clean'] }

    it 'calls proper commands' do
      expect(migrator).to receive(:run).with({ target: 0 })

      expect {
        task.invoke
      }.to output("<= db:clean executed\n").to_stdout
    end

    context 'with custom migration_options' do
      before do
        ROM::SQL::RakeSupport.migration_options = { table: :custom_table, column: :custom_column }
      end

      it 'calls proper commands' do
        expect(migrator).to receive(:run).with({ target: 0, table: :custom_table, column: :custom_column })

        expect {
          task.invoke
        }.to output("<= db:clean executed\n").to_stdout
      end
    end
  end

  context 'db:create_migration' do
    let(:task) { Rake::Task['db:create_migration'] }

    context 'without NAME' do
      it 'exit without creating any file' do
        expect(File).to_not receive(:write)

        expect {
          expect {
            task.execute
          }.to output(/No NAME specified/).to_stdout
        }.to raise_error(SystemExit)
      end
    end

    context 'with NAME' do
      let(:dirname) { 'tmp/db/migrate' }
      let(:name) { 'foo_bar' }
      let(:version) { '001' }
      let(:filename) { "#{version}_#{name}.rb" }
      let(:path) { File.join(dirname, filename) }

      it 'calls proper commands with default VERSION' do
        expect(migrator).to receive(:create_file).with(name).and_return(path)

        expect {
          task.execute(
            Rake::TaskArguments.new([:name], [name])
          )
        }.to output("<= migration file created #{path}\n").to_stdout
      end

      it 'calls proper commands with manualy set VERSION' do
        expect(migrator).to receive(:create_file).with(name, version).and_return(path)

        expect {
          task.execute(
            Rake::TaskArguments.new([:name, :version], [name, version])
          )
        }.to output("<= migration file created #{path}\n").to_stdout
      end
    end
  end
end
