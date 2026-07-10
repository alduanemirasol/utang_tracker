/// How the debts list is ordered for the store owner.
enum DebtSortOrder {
  newest('Newest'),
  highestBalance('Highest balance'),
  lowestBalance('Lowest balance');

  const DebtSortOrder(this.label);

  final String label;
}
