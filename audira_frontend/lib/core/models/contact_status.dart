enum ContactStatus {
  pending('PENDING', 'Pendiente'),
  inProgress('IN_PROGRESS', 'En proceso'),
  resolved('RESOLVED', 'Resuelto'),
  closed('CLOSED', 'Cerrado');

  final String value;
  final String label;

  const ContactStatus(this.value, this.label);

  static ContactStatus fromString(String value) {
    return ContactStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ContactStatus.pending,
    );
  }
}
