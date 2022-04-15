require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run all specs in compat mode"
task "spec:compat" do
  ENV["ROM_COMPAT"] = "true"
  Rake::Task["spec"].invoke
end

task default: [:spec]
