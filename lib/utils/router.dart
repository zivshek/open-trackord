import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:trackord/blocs/categories_bloc.dart';
import 'package:trackord/blocs/clusters_bloc.dart';
import 'package:trackord/blocs/history_bloc.dart';
import 'package:trackord/screens/category.dart';
import 'package:trackord/screens/cluster.dart';
import 'package:trackord/screens/history.dart';
import 'package:trackord/screens/indi_chart.dart';
import 'package:trackord/screens/main_screen.dart';
import 'package:trackord/screens/multi_chart.dart';
import 'package:trackord/screens/record.dart';

GoRouter getRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MainScreen(),
        routes: [
          GoRoute(
            path: 'edit_category/:categoryId',
            builder: (context, state) {
              final categoryId = int.parse(state.pathParameters['categoryId']!);
              final categoriesState = context.read<CategoriesBloc>().state;
              if (categoriesState is CategoriesLoaded) {
                final category = categoriesState.categories.firstWhereOrNull(
                  (c) => c.id == categoryId,
                );
                if (category != null) {
                  final clustersState = context.read<ClustersBloc>().state;
                  if (clustersState is ClustersLoaded) {
                    final cluster = clustersState.clusters.firstWhereOrNull(
                      (c) => c.id == category.clusterId,
                    );
                    if (cluster != null) {
                      return CategoryPage(cluster: cluster, category: category);
                    }
                  }
                }
              }
              // Show a loading indicator while categories are being loaded
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'new_category/:clusterId',
            builder: (context, state) {
              final clusterId = int.parse(state.pathParameters['clusterId']!);
              final clustersState = context.read<ClustersBloc>().state;
              if (clustersState is ClustersLoaded) {
                final cluster = clustersState.clusters.firstWhereOrNull(
                  (c) => c.id == clusterId,
                );
                if (cluster != null) {
                  return CategoryPage(cluster: cluster);
                }
              }
              // Show a loading indicator while clusters are being loaded
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'new_cluster',
            builder: (context, state) => const ClusterPage(),
          ),
          GoRoute(
            path: 'edit_cluster/:clusterId',
            builder: (context, state) {
              final clusterId = int.parse(state.pathParameters['clusterId']!);
              final clustersState = context.read<ClustersBloc>().state;
              if (clustersState is ClustersLoaded) {
                final cluster = clustersState.clusters.firstWhereOrNull(
                  (c) => c.id == clusterId,
                );
                if (cluster != null) {
                  return ClusterPage(cluster: cluster);
                }
              }
              // Show a loading indicator while clusters are being loaded
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'new_record/:categoryId',
            builder: (context, state) {
              final categoryId = int.parse(state.pathParameters['categoryId']!);
              final categoriesState = context.read<CategoriesBloc>().state;

              if (categoriesState is CategoriesLoaded) {
                final category = categoriesState.categories.firstWhereOrNull(
                  (c) => c.id == categoryId,
                );
                if (category != null) {
                  return RecordPage(
                    category: category,
                    record: null,
                  );
                }
              }
              // Show a loading indicator while categories are being loaded
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'edit_record/:recordId',
            builder: (context, state) {
              final recordId = int.parse(state.pathParameters['recordId']!);
              final historyState = context.read<HistoryBloc>().state;

              if (historyState is HistoryLoaded) {
                final record = historyState.records.firstWhereOrNull(
                  (c) => c.id == recordId,
                );
                if (record != null) {
                  final categoriesState = context.read<CategoriesBloc>().state;

                  if (categoriesState is CategoriesLoaded) {
                    final category =
                        categoriesState.categories.firstWhereOrNull(
                      (c) => c.id == record.categoryId,
                    );
                    if (category != null) {
                      return RecordPage(
                        category: category,
                        record: record,
                      );
                    }
                  }
                }
              }
              // Show a loading indicator while categories are being loaded
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'indi_chart/:categoryId',
            builder: (context, state) {
              final categoryId = int.parse(state.pathParameters['categoryId']!);
              final categoriesState = context.read<CategoriesBloc>().state;

              if (categoriesState is CategoriesLoaded) {
                final category = categoriesState.categories.firstWhere(
                  (c) => c.id == categoryId,
                  orElse: () => throw Exception('Category not found'),
                );
                return IndiChartPage(category: category);
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'category_history/:categoryId',
            builder: (context, state) {
              final categoryId = int.parse(state.pathParameters['categoryId']!);
              final categoriesState = context.read<CategoriesBloc>().state;

              if (categoriesState is CategoriesLoaded) {
                final category = categoriesState.categories.firstWhereOrNull(
                  (c) => c.id == categoryId,
                );

                if (category != null) {
                  return HistoryPage(category: category);
                }
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          GoRoute(
            path: 'multi_chart',
            builder: (context, state) => const MultiChartPage(),
          ),
          GoRoute(
            path: 'licenses',
            builder: (context, state) => const LicensePage(
              applicationName: 'Trackord',
            ),
          )
        ],
      ),
    ],
  );
}
