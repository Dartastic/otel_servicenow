// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_servicenow_suppression.dart';

const _tracerName = 'dartastic_otel_libs_servicenow';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a ServiceNow Table API call in a CLIENT span. [table] is
/// the sys_class (e.g. `incident`, `change_request`, `sc_request`).
Future<T> tracedServicenowTable<T>({
  required String table,
  required String action,
  required String instance,
  required Future<T> Function() invoke,
  String? sysId,
}) async {
  if (servicenowInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'servicenow.table': table,
    'servicenow.action': action,
    'servicenow.operation': '$table.$action',
    'servicenow.instance': instance,
  };
  if (sysId != null) m['servicenow.sys_id'] = sysId;

  final span = _tracer().startSpan(
    'servicenow $table.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
