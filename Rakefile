require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rbconfig"

# Load RSpec tasks as the :spec task
RSpec::Core::RakeTask.new(:spec)

# Set default task to test
task default: :test

namespace :test do
  desc 'Setup test environment'
  task :before do
    @web_server = Process.spawn(
      File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']),
      'spec/fixture_server.rb',
      in: :close
    )
    
    sleep 0
  end

  desc 'Teardown test environment'
  task :after do
    Process.kill 'KILL', @web_server
  end
end

desc 'Run test suite'
task :test do
  Rake::Task['test:before'].invoke

  begin
    # Change this to your needs
    Rake::Task[:spec].invoke
  ensure
    Rake::Task['test:after'].invoke
  end
end
