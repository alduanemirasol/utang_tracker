enum DebtSortOrder {
  newest('Newest'),
  highestBalance('Highest balance'),
  lowestBalance('Lowest balance');

  const DebtSortOrder(this.label);

  final String label;
}
