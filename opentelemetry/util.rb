require 'opentelemetry/exporter/otlp'
require 'opentelemetry/sdk'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/runtime'

module OpenTelemetrySample
  module Util
    def self.configure_metrics_and_tracing
      # Before doing anything, configure the default runtime with OpenTelemetry metrics. Unlike OpenTelemetry tracing in
      # Temporal, OpenTelemetry metrics does not use the Ruby OpenTelemetry library, but rather an internal one.
      Temporalio::Runtime.default = Temporalio::Runtime.new(
        telemetry: Temporalio::Runtime::TelemetryOptions.new(
          metrics: Temporalio::Runtime::MetricsOptions.new(
            opentelemetry: Temporalio::Runtime::OpenTelemetryMetricsOptions.new(
              url: 'http://127.0.0.1:4317',
              durations_as_seconds: true
            )
          )
        )
      )
      # Globally configure the Ruby OpenTelemetry library for tracing purposes. As of this writing, OpenTelemetry Ruby does
      # not support OTLP over gRPC, so we use the HTTP endpoint instead.
      OpenTelemetry::SDK.configure do |c|
        c.service_name = 'my-service'
        c.use_all
        # Currently we must use a batch processor (which is better for production anyways) instead of a simple span
        # processor because some things OTLP does in the workflow are illegal, so it's better in the background. See
        # https://github.com/temporalio/sdk-ruby/issues/251.
        processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
          OpenTelemetry::Exporter::OTLP::Exporter.new(
            endpoint: 'http://localhost:4318/v1/traces'
          )
        )
        c.add_span_processor(processor)
        # We need to shutdown the batch span processor on process exit to flush spans
        at_exit { processor.shutdown }
      end
    end
  end
end
