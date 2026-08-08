enum CustomerSortOrder {
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A'),
  newest('Newest'),
  oldest('Oldest');

  const CustomerSortOrder(this.label);

  final String label;
}