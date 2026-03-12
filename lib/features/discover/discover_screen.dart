import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'calendar_tab.dart';
import 'topics_tab.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Discover',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary(context),
            indicatorWeight: 3,
            labelColor: AppColors.primary(context),
            unselectedLabelColor: AppColors.textSecondary(context),
            labelStyle: GoogleFonts.raleway(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.raleway(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Calendar'),
              Tab(text: 'Topics'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CalendarTab(),
            TopicsTab(),
          ],
        ),
      ),
    );
  }
}
