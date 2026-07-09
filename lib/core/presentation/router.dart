import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/presentation/app_shell.dart';
import 'package:utang_tracker/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:utang_tracker/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:utang_tracker/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:utang_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:utang_tracker/features/debt_items/presentation/screens/debt_item_form_screen.dart';
import 'package:utang_tracker/features/debts/presentation/screens/debt_detail_screen.dart';
import 'package:utang_tracker/features/debts/presentation/screens/debt_form_screen.dart';
import 'package:utang_tracker/features/debts/presentation/screens/debt_list_screen.dart';
import 'package:utang_tracker/features/payments/presentation/screens/payment_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/debts',
              name: 'debtList',
              builder: (context, state) => const DebtListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'debtNew',
                  builder: (context, state) => DebtFormScreen(
                    customerId: state.uri.queryParameters['customerId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: 'debtDetail',
                  builder: (context, state) => DebtDetailScreen(
                    debtId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'debtEdit',
                      builder: (context, state) => DebtFormScreen(
                        debtId: state.pathParameters['id'],
                      ),
                    ),
                    GoRoute(
                      path: 'items/new',
                      name: 'debtItemNew',
                      builder: (context, state) => DebtItemFormScreen(
                        debtId: state.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'items/:itemId/edit',
                      name: 'debtItemEdit',
                      builder: (context, state) => DebtItemFormScreen(
                        debtId: state.pathParameters['id']!,
                        itemId: state.pathParameters['itemId'],
                      ),
                    ),
                    GoRoute(
                      path: 'payments/new',
                      name: 'paymentNew',
                      builder: (context, state) {
                        final amountParam =
                            state.uri.queryParameters['amount'];
                        final prefill = amountParam != null
                            ? double.tryParse(amountParam)
                            : null;
                        return PaymentFormScreen(
                          debtId: state.pathParameters['id']!,
                          prefillAmount: prefill,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'payments/:paymentId/edit',
                      name: 'paymentEdit',
                      builder: (context, state) => PaymentFormScreen(
                        debtId: state.pathParameters['id']!,
                        paymentId: state.pathParameters['paymentId'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customers',
              name: 'customerList',
              builder: (context, state) => const CustomerListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: 'customerNew',
                  builder: (context, state) => const CustomerFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: 'customerDetail',
                  builder: (context, state) => CustomerDetailScreen(
                    customerId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: 'customerEdit',
                      builder: (context, state) => CustomerFormScreen(
                        customerId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
