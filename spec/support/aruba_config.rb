require 'aruba/rspec'
Aruba.configure do |config|
  config.startup_wait_time = 0.7
  config.io_wait_timeout = 2
  config.exit_timeout = 3
  config.activate_announcer_on_command_failure = [:command, :stdout, :stderr]
end


