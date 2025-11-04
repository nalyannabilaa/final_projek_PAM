import 'package:flutter/material.dart';
import '../../widgets/custom_navbar.dart';
import '../../views/home/home_page.dart';
import '../../views/expedition/expedition_list_page.dart';
import '../../views/logbook/logbook_page.dart';
import '../../views/profile/profile_page.dart';

class HomeWrapper extends StatefulWidget {
  final String username;
  final int leaderId;

  const HomeWrapper({
    super.key,
    required this.username,
    required this.leaderId,
  });

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(username: widget.username, leaderId: widget.leaderId),
      const ExpeditionListPage(),
      const LogbookPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
