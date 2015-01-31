require 'spec_helper'

namespace :db do
  task :load_setup  do
  end
end

describe 'MigrationTasks' do
  context 'db:reset' do
    it 'calls proper commands' do
      expect(ROM::SQL::Migration).to receive(:run).with(target: 0)
      expect(ROM::SQL::Migration).to receive(:run)
      expect(STDOUT).to receive(:puts).with("<= db:reset executed")

      Rake::Task["db:reset"].invoke
    end
  end

  context 'db:migrate' do
    context 'with VERSION' do
      it 'calls proper commands' do
        expect(ROM::SQL::Migration).to receive(:run).with(target: 1)
        expect(STDOUT).to receive(:puts)
          .with("<= db:migrate version=[1] executed")

        Rake::Task["db:migrate"].invoke(1)
      end
    end

    context 'without VERSION' do
      it 'calls proper commands' do
        expect(ROM::SQL::Migration).to receive(:run)
        expect(STDOUT).to receive(:puts).with("<= db:migrate executed")

        Rake::Task["db:migrate"].execute
      end
    end
  end

  context 'db:clean' do
    it 'calls proper commands' do
      expect(ROM::SQL::Migration).to receive(:run).with(target: 0)
      expect(STDOUT).to receive(:puts).with("<= db:clean executed")

      Rake::Task["db:clean"].invoke
    end
  end

  context 'db:create_migration' do
    context 'without NAME' do
      it 'exit without creating any file' do
        expect(File).to_not receive(:write)
        expect(STDOUT).to receive(:puts).with(/No NAME specified/)

        expect {
          Rake::Task["db:create_migration"].execute
        }.to raise_error(SystemExit)
      end
    end

    context 'with NAME' do
      let(:dirname) { 'db/migration' }
      let(:name) { 'foo_bar' }
      let(:version) { '001' }
      let(:filename) { "#{version}_#{name}.rb" }
      let(:path) { File.join(dirname, filename) }

      before do
        expect(ROM::SQL::Migration).to receive(:path).and_return(dirname)
      end

      it 'calls proper commands with default VERSION' do
        time = double(utc: double(strftime: '001'))
        expect(Time).to receive(:now).and_return(time)
        expect(FileUtils).to receive(:mkdir_p).with(dirname)
        expect(File).to receive(:write).with(path, /ROM::SQL::Migration/)
        expect(STDOUT).to receive(:puts).with(path)

        Rake::Task["db:create_migration"].execute(Rake::TaskArguments.new(
          [:name], [name]))
      end

      it 'calls proper commands with manualy set VERSION' do
        expect(FileUtils).to receive(:mkdir_p).with(dirname)
        expect(File).to receive(:write).with(path, /ROM::SQL::Migration/)
        expect(STDOUT).to receive(:puts).with(path)

        Rake::Task["db:create_migration"].execute(Rake::TaskArguments.new(
          [:name, :version], [name, version]))
      end
    end
  end
end
