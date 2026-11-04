// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_servicenow/otel_servicenow.dart';

/// Traces ServiceNow Table calls with OpenTelemetry.
///
/// `otel_servicenow` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each ServiceNow Table call in
/// [tracedServicenowTable]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'servicenow-example');

  // Wraps a ServiceNow Table API call in a CLIENT span.
  final servicenowTableId = await tracedServicenowTable<String>(
    table: 'orders',
    action: 'example',
    instance: 'example',
    sysId: 'sys_8f3a2c',
    invoke: () async {
      // Make the ServiceNow Table call here, then report what it returned.
      return 'servicenow_8f3a2c';
    },
  );
  OTelLog.info('tracedServicenowTable returned $servicenowTableId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutServicenowInstrumentationAsync.
  await runWithoutServicenowInstrumentationAsync(
    () => tracedServicenowTable<String>(
      table: 'orders',
      action: 'example',
      instance: 'example',
      sysId: 'sys_8f3a2c',
      invoke: () async {
        return 'servicenow_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
