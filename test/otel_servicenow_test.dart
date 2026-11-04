// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_servicenow/otel_servicenow.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_servicenow-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('incident.create records CLIENT span', () async {
    await tracedServicenowTable<String>(
      table: 'incident',
      action: 'create',
      instance: 'acme.service-now.com',
      sysId: 'abc-123',
      invoke: () async => 'INC0001',
    );
    final a = attrsOf(spans.findSpanByName('servicenow incident.create')!);
    expect(a['servicenow.table'], 'incident');
    expect(a['servicenow.action'], 'create');
    expect(a['servicenow.operation'], 'incident.create');
    expect(a['servicenow.instance'], 'acme.service-now.com');
    expect(a['servicenow.sys_id'], 'abc-123');
  });

  test('suppression skips spans', () async {
    await runWithoutServicenowInstrumentationAsync(() async {
      await tracedServicenowTable<String>(
        table: 't',
        action: 'a',
        instance: 'i',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('servicenow '), isEmpty);
  });
}
