require 'spec_helper'

namespace :db do
  task :setup do
    #noop
  end
end

RSpec.describe 'MigrationTasks', :postgres, skip_tables: true do
  include_context 'database setup'

  let(:migrator) { container.gateways[:default].migrator }

  before do
    allow(ROM::SQL::RakeSupport).to receive(:env) { conf }
  end

  context 'db:reset' do
    it 'calls proper commands' do
      expect(migrator).to receive(:run).with(target: 0)
      expect(migrator).to receive(:run)

      expect {
        Rake::Task["db:reset"].invoke
      }.to output("<= db:reset executed\n").to_stdout
    end
  end

  context 'db:migrate' do
    context 'with VERSION' do
      it 'calls proper commands' do
        expect(migrator).to receive(:run).with(target: 1)

        expect {
          Rake::Task["db:migrate"].invoke(1)
        }.to output("<= db:migrate version=[1] executed\n").to_stdout
      end
    end

    context 'without VERSION' do
      it 'calls proper commands' do
        expect(migrator).to receive(:run)

        expect {
          Rake::Task["db:migrate"].execute
        }.to output("<= db:migrate executed\n").to_stdout
      end
    end
  end

  context 'db:clean' do
    it 'calls proper commands' do
      expect(migrator).to receive(:run).with(target: 0)

      expect {
        Rake::Task["db:clean"].invoke
      }.to output("<= db:clean executed\n").to_stdout
    end
  end

  context 'db:create_migration' do
    context 'without NAME' do
      it 'exit without creating any file' do
        expect(File).to_not receive(:write)

        expect {
          expect {
            Rake::Task["db:create_migration"].execute
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
          Rake::Task["db:create_migration"].execute(
            Rake::TaskArguments.new([:name], [name]))
        }.to output("<= migration file created #{path}\n").to_stdout
      end

      it 'calls proper commands with manualy set VERSION' do
        expect(migrator).to receive(:create_file).with(name, version).and_return(path)

        expect {
          Rake::Task["db:create_migration"].execute(
            Rake::TaskArguments.new([:name, :version], [name, version]))
        }.to output("<= migration file created #{path}\n").to_stdout
      end
    end
  end
end
