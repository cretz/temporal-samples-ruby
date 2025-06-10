# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'temporalio/client'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/runtime'
require_relative 'greeting_workflow'
require_relative 'util'

# Configure metrics and tracing
OpenTelemetrySample::Util.configure_metrics_and_tracing

# Demonstrate that we can create a custom metric right on the runtime, though most users won't need this
Temporalio::Runtime.default.metric_meter.create_metric(:gauge, 'my-starter-gauge', value_type: :float)
                   .with_additional_attributes({ 'my-group-attr' => 'simple-starters' })
                   .record(1.23)

# Create a client with the tracing interceptor set using the tracer
tracer = OpenTelemetry.tracer_provider.tracer('temporal_ruby_sample', '0.1.0')
client = Temporalio::Client.connect(
  'localhost:7233',
  'default',
  interceptors: [Temporalio::Contrib::OpenTelemetry::TracingInterceptor.new(tracer)]
)

# Demonstrate an arbitrary outer span. Most users may not explicitly create outer spans before using clients and rather
# solely rely on the implicit ones created in the client via interceptor, but this demonstrates that it can be done.
tracer.in_span('my-client-span', attributes: { 'my-group-attr' => 'simple-client' }) do
  # Run workflow
  puts 'Executing workflow'
  result = client.execute_workflow(
    OpenTelemetrySample::GreetingWorkflow,
    'User', # Workflow argument
    id: 'opentelemetry-sample-workflow-id',
    task_queue: 'opentelemetry-sample'
  )
  puts "Workflow result: #{result}"
end
