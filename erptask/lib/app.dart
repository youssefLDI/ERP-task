import 'package:erptask/themes/light_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erptask/features/auth/data/firebase_auth_repo.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:erptask/features/auth/presentation/cubits/auth_states.dart';
import 'package:erptask/features/auth/presentation/pages/auth_page.dart';
import 'package:erptask/features/documents/data/firebase_document_repo.dart';
import 'package:erptask/features/documents/presentation/cubits/document_cubit.dart';
import 'package:erptask/features/documents/presentation/pages/documents_page.dart';
import 'package:erptask/features/folders/presentation/pages/folder_page.dart';
import 'package:erptask/features/folders/data/firebase_folder_repo.dart';
import 'package:erptask/features/folders/presentation/cubits/folder_cubit.dart';

class MyApp extends StatelessWidget {
  final authRepo = FirebaseAuthRepo();
  final documentRepo = FirebaseDocumentRepo();
  final folderRepo = FirebaseFolderRepo();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide cubits to the app
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepo: authRepo)..checkAuth(),
        ),
        BlocProvider<DocumentCubit>(
          create:
              (context) => DocumentCubit(
                documentRepo: documentRepo,
                folderRepo: folderRepo,
              ),
        ),
        BlocProvider<FolderCubit>(
          create: (context) => FolderCubit(folderRepo: folderRepo),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Document Manager',
        theme: lightMode,
        home: BlocConsumer<AuthCubit, AuthState>(
          builder: (context, authState) {
            print(authState);

            // Unauthenticated --> authPage (Register / Login)
            if (authState is Unauthenticated) {
              return const AuthPage();
            }

            // Authenticated --> show main navigation
            if (authState is Authnticated) {
              final userId = context.read<AuthCubit>().currentUser?.uid;
              return _MainNav(userId: userId!);
            }
            // Loading
            else {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ),
    );
  }
}

class _MainNav extends StatefulWidget {
  final String userId;
  const _MainNav({required this.userId});
  @override
  State<_MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<_MainNav> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [DocumentsPage(), FoldersPage(userId: widget.userId)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Documents',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Folders'),
        ],
      ),
    );
  }
}
