require 'spec_helper'

namespace :db do
  task :setup  do
    # noop
  end
end

describe 'MigrationTasks' do
  before do
    ROM.setup(:sql, ['postgres://localhost/rom'])
    ROM.finalize
  end

  let(:migrator) { ROM.env.repositories[:default].migrator }

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

      before do
        expect(migrator).to receive(:path).and_return(dirname)
      end

      it 'calls proper commands with default VERSION' do
        time = double(utc: double(strftime: '001'))
        expect(Time).to receive(:now).and_return(time)
        expect(FileUtils).to receive(:mkdir_p).with(dirname)
        expect(File).to receive(:write).with(path, /ROM.env.repositories\[:default\]/)

        expect {
          Rake::Task["db:create_migration"].execute(
            Rake::TaskArguments.new([:name], [name]))
        }.to output(path+"\n").to_stdout
      end

      it 'calls proper commands with manualy set VERSION' do
        expect(FileUtils).to receive(:mkdir_p).with(dirname)
        expect(File).to receive(:write).with(path, /ROM.env.repositories\[:default\]/)

        expect {
          Rake::Task["db:create_migration"].execute(
            Rake::TaskArguments.new([:name, :version], [name, version]))
        }.to output(path+"\n").to_stdout
      end
    end
  end
end
