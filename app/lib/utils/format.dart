String _two(int n) => n.toString().padLeft(2, '0');

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String formatDateTime(DateTime d) =>
    '${_two(d.day)} ${_meses[d.month - 1]} ${d.year}, ${_two(d.hour)}:${_two(d.minute)}';
