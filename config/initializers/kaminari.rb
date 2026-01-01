# frozen_string_literal: true

# Configure Kaminari for Solid Queue models
Kaminari.configure do |config|
  config.default_per_page = 25
  config.window = 4
  config.outer_window = 0
  config.left = 0
  config.right = 0
end

# Include Kaminari support in SolidQueue models
[
  SolidQueue::Job,
  SolidQueue::FailedExecution,
  SolidQueue::ClaimedExecution,
  SolidQueue::ReadyExecution,
  SolidQueue::ScheduledExecution
].each do |model|
  model.include(Kaminari::ActiveRecordExtension) unless model.included_modules.include?(Kaminari::ActiveRecordExtension)
end
