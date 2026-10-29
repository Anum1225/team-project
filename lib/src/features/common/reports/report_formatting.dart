part of 'reporting.dart';

int _reportNumber(Object? value) => value is num ? value.toInt() : 0;

String _reportCount(Object? value) =>
    value == null ? '—' : '${_reportNumber(value)}';
