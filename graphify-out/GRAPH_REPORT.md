# Graph Report - sanayi_app  (2026-09-04)

## Corpus Check
- 253 files · ~171,179 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2311 nodes · 3282 edges · 144 communities (116 shown, 22 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 32 edges (avg confidence: 0.81)
- Token cost: 0 input · 367,558 output

## Community Hubs (Navigation)
- Mechanic Appointments
- Mechanic Appointments (2)
- Windows Desktop Runner
- Booking Flow
- Customer Appointments
- macOS Flutter Embedding
- App Theme/Design System
- Customer Appointments (2)
- Admin/Build Tooling
- Mechanic Appointments (3)
- Mechanic Appointments (4)
- Mechanic Auth
- Data Repositories
- Mechanic Appointments (5)
- Customer Auth Screens
- Data Models
- Mechanic Appointments (6)
- Home Widgets
- Home Widgets (2)
- Shared Widgets
- Home Screen
- Search Screen
- Mechanic Home
- Cloud Functions
- Customer Appointments (3)
- Mechanic Notifications
- Linux Desktop Runner
- Data Repositories (2)
- Service Categories
- Auth Core
- Notifications Screen
- Service Listing
- Mechanic Detail Widgets
- Mechanic Appointments (7)
- Mechanic Auth (2)
- Customer Appointments (4)
- Mechanic Appointments (8)
- Customer Appointments (5)
- Booking Widgets
- App Entry/Root
- Service Listing Widgets
- Mechanic Detail Screen
- Widget/Unit Tests
- Mechanic Appointments (9)
- Widget/Unit Tests (2)
- Widget/Unit Tests (3)
- Graphify Skill Docs
- Mechanic Profile
- Home Widgets (3)
- Mechanic Appointments (10)
- Search Widgets
- Category Widgets
- Service Categories (2)
- Shared Widgets (2)
- Mechanic Appointments (11)
- Service Categories (3)
- Project Root Files
- Home Widgets (4)
- Cloud Functions (2)
- Utilities
- Category Widgets (2)
- Widget/Unit Tests (4)
- Trust Signals UI
- Widget/Unit Tests (5)
- Category Widgets (3)
- Service Listing (2)
- Test Utilities
- Mechanic Detail Widgets (2)
- Windows Desktop Runner (2)
- Mechanic Profile (2)
- Service Categories (4)
- Category Widgets (4)
- Mechanic Appointments (12)
- Appointment Widgets
- Trust Signals UI (2)
- Web Platform
- Mechanic Home (2)
- Category Widgets (5)
- Home Screen (2)
- Booking Widgets (2)
- Mechanic Bulk Upload Script
- Home Screen (3)
- Graphify Skill Docs (2)
- Graphify Skill Docs (3)
- Graphify Skill Docs (4)
- Data Models (2)
- Cloud Functions Source
- Mechanic Detail Widgets (3)
- Widget/Unit Tests (6)
- Project Root Files (2)
- Home Screen (4)
- Cloud Functions Scripts
- Data Repositories (3)
- Widget/Unit Tests (7)
- Graphify Skill Docs (5)
- Home Widgets (5)
- Utilities (2)
- Mechanic Bulk Upload Script (2)
- Utilities (3)
- Data Repositories (4)
- Data Repositories (5)
- Service Categories (5)
- Service Categories (6)
- Service Categories (7)
- Service Categories (8)
- Service Categories (9)
- Service Categories (10)
- Service Categories (11)
- Home Widgets (6)
- Widgets (misc)
- Graphify Skill Docs (6)
- Graphify Skill Docs (7)
- Appointment Widgets (2)
- Mechanic Appointments (13)
- Data Models (3)
- Utilities (4)
- Android App Config
- Auth Core (2)
- Utilities (5)
- Project Root Files (3)
- Web Platform (2)
- Auth Core (3)
- iOS App Icons/Assets
- Auth Core (4)
- Feature Config
- Mechanic Appointments (14)
- Mechanic Appointments (15)
- Mechanic Appointments (16)
- Mechanic Appointments (17)
- Booking Flow (2)
- Booking Flow (3)
- macOS App Icons/Assets
- Project Root Files (4)
- App Fonts
- Project Root Files (5)
- Project Root Files (6)
- iOS App Icons/Assets (2)
- Community 142

## God Nodes (most connected - your core abstractions)
1. `_` - 32 edges
2. `Win32Window` - 24 edges
3. `/graphify command` - 14 edges
4. `MessageHandler` - 12 edges
5. `Mechanic` - 10 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `scripts` - 9 edges
10. `MessageHandler` - 9 edges

## Surprising Connections (you probably didn't know these)
- `flutter run Device-Offline Failure (attempt 1)` --semantically_similar_to--> `flutter run Device-Offline Failure (attempt 2)`  [INFERRED] [semantically similar]
  build_log.txt → build_log2.txt
- `Linux Top-Level Build Target (sanayi_app)` --semantically_similar_to--> `Windows Top-Level Build Target (sanayi_app)`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `Kotlin Gradle Plugin (KGP) Migration Warning` --shares_data_with--> `sanayi_app pubspec Dependencies (Firebase/Auth stack)`  [INFERRED]
  build_result.txt → pubspec.yaml
- `sanayi_app Web App Shell (title/manifest)` --shares_data_with--> `sanayi_app pubspec Dependencies (Firebase/Auth stack)`  [INFERRED]
  web/index.html → pubspec.yaml
- `Google Sign-In Web Client ID Meta Tag` --shares_data_with--> `sanayi_app pubspec Dependencies (Firebase/Auth stack)`  [INFERRED]
  web/index.html → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Graph Query & Self-Improving Recall Loop** — claude_skills_graphify_references_query_query_flow, claude_skills_graphify_references_query_path_flow, claude_skills_graphify_references_query_explain_flow, claude_skills_graphify_references_query_save_result_command, claude_skills_graphify_references_query_reflect_command [INFERRED 0.85]
- **Extra Export Formats (Steps 6b-8)** — claude_skills_graphify_references_exports_wiki_export, claude_skills_graphify_references_exports_neo4j_export, claude_skills_graphify_references_exports_falkordb_export, claude_skills_graphify_references_exports_svg_export, claude_skills_graphify_references_exports_graphml_export, claude_skills_graphify_references_exports_mcp_server, claude_skills_graphify_references_exports_token_benchmark [EXTRACTED 1.00]
- **Core Build Pipeline (Steps 1-9)** — claude_skills_graphify_skill_step1_ensure_installed, claude_skills_graphify_skill_step2_detect_files, claude_skills_graphify_skill_step3_extract, claude_skills_graphify_skill_step4_build_graph, claude_skills_graphify_skill_step4_5_health_check, claude_skills_graphify_skill_step5_label_communities, claude_skills_graphify_skill_step6_obsidian_html, claude_skills_graphify_skill_step9_manifest_cleanup [EXTRACTED 1.00]
- **graphify CLI Workflow (query/path/explain/update)** — claude_graphify_query, claude_graphify_path, claude_graphify_explain, claude_graphify_update [EXTRACTED 1.00]
- **Flutter Desktop Runner Build Pattern (Linux/Windows)** — linux_cmakelists_runner_target, linux_runner_cmakelists_runner_executable, windows_cmakelists_runner_target, windows_runner_cmakelists_runner_executable [INFERRED 0.85]
- **Firebase/Google Sign-In Authentication Stack** — pubspec_dependencies, pubspec_google_sign_in_web, web_index_google_signin_client_id, web_index_recaptcha_container, build_result_kgp_plugin_warning [INFERRED 0.85]

## Communities (144 total, 22 thin omitted)

### Community 0 - "Mechanic Appointments"
Cohesion: 0.02
Nodes (87): Animation, _acceptRequest, _acceptTimeProposal, appointment, appointmentDate, appointmentId, _appointmentRepository, _appointments (+79 more)

### Community 1 - "Mechanic Appointments (2)"
Cohesion: 0.03
Nodes (68): DateTime get, Duration, appointmentDate, appointmentDateAnchorHourUtc, appointmentId, AppointmentStatus, appointmentTime, buildDummyAppointments (+60 more)

### Community 2 - "Windows Desktop Runner"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 3 - "Booking Flow"
Cohesion: 0.04
Nodes (50): _borderColor, build, _buildChip, _chipHeight, _chipWidth, createState, dateLabel, _dates (+42 more)

### Community 4 - "Customer Appointments"
Cohesion: 0.04
Nodes (46): _borderRadius, _bubbleColor, build, _ChatBubble, chatId, _chipSpacing, _controller, createState (+38 more)

### Community 5 - "macOS Flutter Embedding"
Cohesion: 0.05
Nodes (32): Any, cloud_firestore, Cocoa, firebase_app_check, firebase_auth, firebase_core, Flutter, FlutterAppDelegate (+24 more)

### Community 6 - "App Theme/Design System"
Cohesion: 0.04
Nodes (45): AppColors, AppRadius, AppShadows, AppSpacing, AppTextStyles, AppTheme, background, body (+37 more)

### Community 7 - "Customer Appointments (2)"
Cohesion: 0.05
Nodes (42): AppointmentRequest get, ../booking/time_slot_grid.dart, customer_conversation_page.dart, AppointmentRequest, AppointmentRequestStatus, businessId, customerId, date (+34 more)

### Community 8 - "Admin/Build Tooling"
Cohesion: 0.05
Nodes (43): dart:collection, dart:io, package:image/image.dart, bg, _bgThreshold, counts, file, filledCount (+35 more)

### Community 9 - "Mechanic Appointments (3)"
Cohesion: 0.05
Nodes (43): appointment_calendar_view.dart, _acceptRequest, _acceptTimeProposal, appointment, _appointments, count, createState, _CustomerInfoCard (+35 more)

### Community 10 - "Mechanic Appointments (4)"
Cohesion: 0.05
Nodes (40): data/appointment_repository.dart, appointment, _AppointmentCard, appointmentDate, appointmentTime, businessId, _buttonHeight, _cardRadius (+32 more)

### Community 11 - "Mechanic Auth"
Cohesion: 0.05
Nodes (40): ../home/mechanic_home_page.dart, _afterSignedIn, build, _businessNameController, _cancel, _codeController, _confirmCode, _continueAfterMechanicSignIn (+32 more)

### Community 12 - "Data Repositories"
Cohesion: 0.05
Nodes (37): CustomPainter, allMechanics, allServiceCategories, categories, ekspertizCategories, MockData, otherMechanics, popularMechanics (+29 more)

### Community 13 - "Mechanic Appointments (5)"
Cohesion: 0.05
Nodes (39): data/chat_message.dart, data/chat_repository.dart, appointment, _bubbleColor, _ChatBubble, chatId, _controller, createState (+31 more)

### Community 14 - "Customer Auth Screens"
Cohesion: 0.05
Nodes (39): ../home/main_shell.dart, _afterSignedIn, _AuthDialog, _AuthDialogState, build, _codeController, _confirmCode, createState (+31 more)

### Community 15 - "Data Models"
Cohesion: 0.05
Nodes (37): bool get, double?, int?, address, businessId, businessName, email, fromFirestore (+29 more)

### Community 16 - "Mechanic Appointments (6)"
Cohesion: 0.05
Nodes (37): data/appointment.dart, appointment, _AppointmentBlock, appointments, barColor, _borderColor, createState, date (+29 more)

### Community 17 - "Home Widgets"
Cohesion: 0.05
Nodes (35): ../../config/feature_flags.dart, build, _clusterSpacing, HomeTab, _MainServiceCategories, onCategoryTap, _sectionPadding, _showComingSoon (+27 more)

### Community 18 - "Home Widgets (2)"
Cohesion: 0.06
Nodes (34): deriveVehiclesFromAppointments, licensePlate, modelLabel, seen, sorted, Vehicle, vehicles, _AddVehicleRow (+26 more)

### Community 19 - "Shared Widgets"
Cohesion: 0.06
Nodes (33): BoxBorder?, Gradient?, _animationDuration, border, borderRadius, build, child, color (+25 more)

### Community 20 - "Home Screen"
Cohesion: 0.06
Nodes (33): ../appointments/appointments_tab.dart, ../appointments/customer_conversation_list_page.dart, ../categories/ac_climate_category_page.dart, ../categories/battery_electrical_category_page.dart, ../categories/body_paint_category_page.dart, ../categories/brake_system_category_page.dart, ../categories/exhaust_system_category_page.dart, ../categories/glass_lighting_category_page.dart (+25 more)

### Community 21 - "Search Screen"
Cohesion: 0.06
Nodes (32): build, _controller, createState, dispose, _filteredResults, _future, initialCategory, initState (+24 more)

### Community 22 - "Mechanic Home"
Cohesion: 0.06
Nodes (32): ../appointments/mechanic_request_details_page.dart, _appointmentRepository, build, createState, dispose, _EmptyPendingRequestsState, _formatTimeOfDay, _ImportantUpdatesCard (+24 more)

### Community 23 - "Cloud Functions"
Cohesion: 0.07
Nodes (28): firebase-functions, dependencies, firebase-admin, firebase-functions, devDependencies, jest, ts-jest, @types/jest (+20 more)

### Community 24 - "Customer Appointments (3)"
Cohesion: 0.08
Nodes (27): Appointment, appointment, _AppointmentList, AppointmentsTab, _AppointmentsTabState, build, comment, _commentController (+19 more)

### Community 25 - "Mechanic Notifications"
Cohesion: 0.08
Nodes (26): ../appointments/data/appointment.dart, ../appointments/data/appointment_repository.dart, ../appointments/data/chat_message.dart, ../appointments/data/chat_repository.dart, ../appointments/mechanic_conversation_page.dart, _buildPendingRequestTile, createState, _customerLabel (+18 more)

### Community 26 - "Linux Desktop Runner"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 27 - "Data Repositories (2)"
Cohesion: 0.08
Nodes (25): ChangeNotifier, int get, accept, actionNeededCount, _applyRealAppointment, appointmentRequestFromAccepted, AppointmentRequestStore, _combine (+17 more)

### Community 28 - "Service Categories"
Cohesion: 0.09
Nodes (22): BatteryElectricalCategoryPage, build, _cardSpacing, onServiceSelected, _services, BrakeSystemCategoryPage, build, _cardSpacing (+14 more)

### Community 29 - "Auth Core"
Cohesion: 0.08
Nodes (25): google_sign_in_button.dart, _, account, autoSignedInCredential, completer, credential, digits, googleSignInAccounts (+17 more)

### Community 30 - "Notifications Screen"
Cohesion: 0.09
Nodes (23): ../appointments/customer_conversation_page.dart, _acceptSuggestion, chat, createState, _DeclinedRequestCard, dispose, _EmptyState, _firestoreAppointments (+15 more)

### Community 31 - "Service Listing"
Cohesion: 0.09
Nodes (22): ../../data/booking_history.dart, build, count, createState, distribution, _DistributionRow, _filter, _gradient (+14 more)

### Community 32 - "Mechanic Detail Widgets"
Cohesion: 0.11
Nodes (17): build, icon, label, PlaceholderTab, build, SectionLabel, text, build (+9 more)

### Community 33 - "Mechanic Appointments (7)"
Cohesion: 0.09
Nodes (21): appointment.dart, acceptProposedTime, acceptTimeProposal, AppointmentRepository, _collection, fetchAppointmentById, fetchAppointments, fetchPendingAppointments (+13 more)

### Community 34 - "Mechanic Auth (2)"
Cohesion: 0.13
Nodes (22): _WeekNavButton, _WeekNavButtonState, _TypingIndicator, _BusinessPickerDialog, _BusinessPickerDialogState, _MechanicAuthDialog, _MechanicAuthDialogState, MechanicLoginPage (+14 more)

### Community 35 - "Customer Appointments (4)"
Cohesion: 0.10
Nodes (21): chatId, _ConversationRow, createState, CustomerConversationListPage, _CustomerConversationListPageState, _EmptyState, _fillColor, _FilterChip (+13 more)

### Community 36 - "Mechanic Appointments (8)"
Cohesion: 0.10
Nodes (20): AppointmentStatus, Color get, _StatusBarColor, AppointmentStatusPresentation, AppointmentStatus, AppointmentStatusPresentation, color, date (+12 more)

### Community 37 - "Customer Appointments (5)"
Cohesion: 0.12
Nodes (20): _AvailableBadge, _EmptyTabState, _InfoRow, _NewRequestBadge, _NewRequestCard, _ServiceBadge, _SuggestInfoRow, _ActionBar (+12 more)

### Community 38 - "Booking Widgets"
Cohesion: 0.10
Nodes (18): formatFullDate, isSameDay, _monthFull, _weekdayFull, _weekdayShort, build, dates, DateStrip (+10 more)

### Community 39 - "App Entry/Root"
Cohesion: 0.10
Nodes (18): ../../auth/social_auth.dart, dev/dev_mode_launcher.dart, firebase_options.dart, android, DefaultFirebaseOptions, ios, macos, web (+10 more)

### Community 40 - "Service Listing Widgets"
Cohesion: 0.10
Nodes (19): _actionsPadding, _background, _buttonSpacing, _CenterInfo, color, _gradient, icon, label (+11 more)

### Community 41 - "Mechanic Detail Screen"
Cohesion: 0.11
Nodes (18): ../booking/appointment_request_page.dart, build, icon, _InfoCard, mechanic, MechanicDetailPage, _RatingSummaryRow, _RepeatCustomerRateTile (+10 more)

### Community 42 - "Widget/Unit Tests"
Cohesion: 0.12
Nodes (16): ElevatedButton, package:sanayi_app/data/pending_booking_vehicle.dart, package:sanayi_app/models/mechanic.dart, package:sanayi_app/screens/categories/tire_wheel_category_page.dart, package:sanayi_app/screens/home/home_tab.dart, package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart, package:sanayi_app/screens/search/search_tab.dart, package:sanayi_app/widgets/booking/date_strip.dart (+8 more)

### Community 43 - "Mechanic Appointments (9)"
Cohesion: 0.11
Nodes (19): build, build, build, build, _openNotifications, _openRequestDetails, build, build (+11 more)

### Community 44 - "Widget/Unit Tests (2)"
Cohesion: 0.16
Nodes (15): package:flutter_test/flutter_test.dart, package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart, package:sanayi_app/main.dart, package:sanayi_app/mechanic/home/mechanic_home_page.dart, package:sanayi_app/screens/auth/login_page.dart, package:sanayi_app/screens/home/main_shell.dart, main, pumpApp (+7 more)

### Community 45 - "Widget/Unit Tests (3)"
Cohesion: 0.11
Nodes (18): package:sanayi_app/mechanic/appointments/appointment_calendar_view.dart, package:sanayi_app/mechanic/appointments/mechanic_request_details_page.dart, RichText, appointmentId, businessId, customerUid, main, mechanicUid (+10 more)

### Community 46 - "Graphify Skill Docs"
Cohesion: 0.14
Nodes (16): .claude/CLAUDE.md graphify pointer, /graphify add flow, --watch background watcher flow, graphify claude install/uninstall, graphify hook install/uninstall/status, --cluster-only flow, --update incremental re-extraction flow, /graphify add command (+8 more)

### Community 47 - "Mechanic Profile"
Cohesion: 0.11
Nodes (17): data/mechanic_profile.dart, data/mechanic_profile_repository.dart, build, createState, fallback, _fallbackMechanic, icon, _InfoRow (+9 more)

### Community 48 - "Home Widgets (3)"
Cohesion: 0.11
Nodes (17): _arrowButtonSize, build, color, icon, _iconBadgeSize, _iconSize, illustration, onTap (+9 more)

### Community 49 - "Mechanic Appointments (10)"
Cohesion: 0.12
Nodes (16): chatId, ChatMessage, ChatSummary, createdAt, customerDisplayName, fromFirestore, id, isRead (+8 more)

### Community 50 - "Search Widgets"
Cohesion: 0.12
Nodes (16): Mechanic, _avatarBackground, _avatarSize, _borderRadius, build, isOpen, _margin, mechanic (+8 more)

### Community 51 - "Category Widgets"
Cohesion: 0.12
Nodes (16): build, emoji, _headerSpacing, icon, iconColor, _InformationSection, informationText, inspections (+8 more)

### Community 52 - "Service Categories (2)"
Cohesion: 0.12
Nodes (14): build, categories, _controller, createState, dispose, onCategorySelected, _query, title (+6 more)

### Community 53 - "Shared Widgets (2)"
Cohesion: 0.14
Nodes (14): AnimationController, _avatarSize, borderRadius, build, _controller, count, createState, dispose (+6 more)

### Community 54 - "Mechanic Appointments (11)"
Cohesion: 0.13
Nodes (14): data/dummy_appointment.dart, appointment, AppointmentCard, _AppointmentCardStyles, build, daysUntil, icon, _InfoLine (+6 more)

### Community 55 - "Service Categories (3)"
Cohesion: 0.13
Nodes (13): build, _informationText, _inspections, MaintenanceMajorDetailPage, _partsReplacement, _serviceName, build, _informationText (+5 more)

### Community 56 - "Project Root Files"
Cohesion: 0.18
Nodes (14): flutter_lints Analyzer Configuration, Gradle assembleDebug Daemon Crash, Kotlin Gradle Plugin (KGP) Migration Warning, social_auth.dart googleSignInButton() (referenced, path uncertain), Linux Top-Level Build Target (sanayi_app), Linux Flutter Library Build Rules, Linux Runner Executable Target, sanayi_app pubspec Dependencies (Firebase/Auth stack) (+6 more)

### Community 57 - "Home Widgets (4)"
Cohesion: 0.14
Nodes (13): category_illustrations.dart, build, _CallHelpPill, EmergencyHelpCard, _gradient, _illustrationAlpha, _illustrationSize, onTap (+5 more)

### Community 58 - "Cloud Functions (2)"
Cohesion: 0.14
Nodes (13): compileOnSave, compilerOptions, module, noImplicitReturns, noUnusedLocals, outDir, sourceMap, strict (+5 more)

### Community 59 - "Utilities"
Cohesion: 0.14
Nodes (13): current, _dayIndex, _dayOrder, endMinutes, indexOf, isOpenNow, matchesToday, normalized (+5 more)

### Community 60 - "Category Widgets (2)"
Cohesion: 0.14
Nodes (13): _background, build, category, CategoryCard, _iconSize, _iconSpacing, _liftScale, onTap (+5 more)

### Community 61 - "Widget/Unit Tests (4)"
Cohesion: 0.15
Nodes (12): package:firebase_auth_mocks/firebase_auth_mocks.dart, package:sanayi_app/screens/categories/ac_climate_category_page.dart, package:sanayi_app/screens/categories/motor_category_page.dart, package:sanayi_app/screens/home/all_vehicles_page.dart, package:sanayi_app/screens/home/vehicle_repair_category_page.dart, main, openVehicleRepair, pumpApp (+4 more)

### Community 62 - "Trust Signals UI"
Cohesion: 0.15
Nodes (12): Color, build, icon, iconColor, _iconSize, _iconSpacing, label, _labelFontSize (+4 more)

### Community 63 - "Widget/Unit Tests (5)"
Cohesion: 0.15
Nodes (11): package:cloud_firestore/cloud_firestore.dart, package:sanayi_app/data/appointment_request_store.dart, package:sanayi_app/screens/appointments/customer_conversation_list_page.dart, package:sanayi_app/screens/notifications/notifications_page.dart, package:sanayi_app/widgets/home/greeting_bar.dart, main, pumpApp, seedChatWithUnreadMechanicMessage (+3 more)

### Community 64 - "Category Widgets (3)"
Cohesion: 0.17
Nodes (11): ../common/premium_surface.dart, build, icon, _iconBackground, _iconInnerSize, _iconSize, onTap, ServiceEntryCard (+3 more)

### Community 65 - "Service Listing (2)"
Cohesion: 0.17
Nodes (11): ../../data/mechanic_directory_repository.dart, Future, build, createState, _fetchSortedServiceCenters, _future, hizmetTuru, initState (+3 more)

### Community 66 - "Test Utilities"
Cohesion: 0.17
Nodes (11): GoogleSignInPlatform, attemptLightweightAuthentication, authenticate, authorizationRequiresUserInteraction, clientAuthorizationTokensForScopes, disconnect, FakeGoogleSignInPlatform, init (+3 more)

### Community 67 - "Mechanic Detail Widgets (2)"
Cohesion: 0.17
Nodes (10): IconData, icon, label, ServiceCategory, subtitle, build, icon, label (+2 more)

### Community 68 - "Windows Desktop Runner (2)"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 69 - "Mechanic Profile (2)"
Cohesion: 0.17
Nodes (10): build, DevModeLauncher, fetchProfile, fetchRepeatCustomerRate, _firestore, MechanicProfileRepository, ../mechanic/auth/mechanic_login_page.dart, mechanic_profile.dart (+2 more)

### Community 70 - "Service Categories (4)"
Cohesion: 0.17
Nodes (10): build, _cardSpacing, GlassLightingCategoryPage, onServiceSelected, _services, build, CategoryFilterBar, onSelected (+2 more)

### Community 71 - "Category Widgets (4)"
Cohesion: 0.18
Nodes (10): category_card.dart, build, categories, CategoryGrid, _gridSpacing, _maxColumns, _minColumns, onCategoryTap (+2 more)

### Community 72 - "Mechanic Appointments (12)"
Cohesion: 0.18
Nodes (10): chat_message.dart, dart:async, ChatRepository, _firestore, markMessagesRead, _messagesRef, sendMessage, watchChats (+2 more)

### Community 73 - "Appointment Widgets"
Cohesion: 0.18
Nodes (10): AppointmentRequestCard, color, icon, _InfoRow, label, request, _StatusPill, _StatusSection (+2 more)

### Community 74 - "Trust Signals UI (2)"
Cohesion: 0.18
Nodes (10): _backgroundAlpha, _borderAlpha, _borderRadius, build, _fontSize, _horizontalPadding, _iconSize, _iconSpacing (+2 more)

### Community 75 - "Web Platform"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 76 - "Mechanic Home (2)"
Cohesion: 0.22
Nodes (9): ../appointments/mechanic_appointments_screen.dart, build, createState, MechanicHomePage, _MechanicHomePageState, _screens, _selectedIndex, mechanic_home_screen.dart (+1 more)

### Community 77 - "Category Widgets (5)"
Cohesion: 0.20
Nodes (9): EdgeInsets, build, categories, CategoryList, onCategoryTap, padding, _spacing, _tileHeight (+1 more)

### Community 78 - "Home Screen (2)"
Cohesion: 0.22
Nodes (9): build, createState, CustomerProfileTab, _CustomerProfileTabState, dispose, _isSaving, _message, _nameController (+1 more)

### Community 79 - "Booking Widgets (2)"
Cohesion: 0.22
Nodes (9): build, _ContactInfoSheetContent, _ContactInfoSheetContentState, createState, dispose, _kvkkAccepted, _nameController, _phoneController (+1 more)

### Community 80 - "Mechanic Bulk Upload Script"
Cohesion: 0.20
Nodes (9): dependencies, firebase-admin, description, firebase-admin, name, private, scripts, upload (+1 more)

### Community 81 - "Home Screen (3)"
Cohesion: 0.28
Nodes (7): ../categories/all_categories_page.dart, ../../data/mock_data.dart, build, EkspertizPage, build, SigortaPage, ../service_listing/service_listing_page.dart

### Community 82 - "Graphify Skill Docs (2)"
Cohesion: 0.22
Nodes (9): Step 7a: FalkorDB export, Step 7c: GraphML export, Step 7d: MCP stdio server, Step 7: Neo4j export, Step 7b: SVG export, Step 8: Token reduction benchmark, Step 6b: Wiki export, Step 9: Save manifest, update cost tracker, clean up (+1 more)

### Community 83 - "Graphify Skill Docs (3)"
Cohesion: 0.28
Nodes (9): Confidence score rubric, Hyperedge rule, Node ID format rule, Semantic similarity rule, Extraction subagent prompt, Part A: Structural (AST) extraction, Part B: Semantic extraction (subagents), Part C: Merge AST + semantic (+1 more)

### Community 84 - "Graphify Skill Docs (4)"
Cohesion: 0.22
Nodes (9): GitHub clone flow (single/multi repo), graphify merge-graphs command, Multi-subfolder / monorepo merge flow, BFS traversal mode, DFS traversal mode, /graphify query flow, Step 0: Constrained query expansion, /graphify query command (+1 more)

### Community 85 - "Data Models (2)"
Cohesion: 0.22
Nodes (8): DateTime?, authorName, comment, date, hasPhoto, helpfulCount, rating, Review

### Community 86 - "Cloud Functions Source"
Cohesion: 0.44
Nodes (6): updateRepeatCustomerRates, writeRepeatCustomerRate(), CompletedAppointment, computeRepeatCustomerRates(), fetchCompletedAppointments(), RepeatCustomerRateResult

### Community 87 - "Mechanic Detail Widgets (3)"
Cohesion: 0.22
Nodes (8): build, _CircleIconButton, DetailActionBar, icon, onBook, onCall, onNavigate, onTap

### Community 88 - "Widget/Unit Tests (6)"
Cohesion: 0.25
Nodes (7): package:fake_cloud_firestore/fake_cloud_firestore.dart, package:sanayi_app/utils/firebase_instances.dart, package:sanayi_app/widgets/service_listing/service_center_card.dart, main, main, pumpCard, TextField

### Community 89 - "Project Root Files (2)"
Cohesion: 0.25
Nodes (8): Graphify Knowledge Graph Workflow, graphify explain command, graphify-out/graph.json, graphify path command, graphify query command, graphify-out/GRAPH_REPORT.md, graphify update command, graphify-out/wiki/index.md

### Community 90 - "Home Screen (4)"
Cohesion: 0.25
Nodes (7): ../../data/pending_booking_vehicle.dart, AllVehiclesPage, build, onCategoryTap, _rowSpacing, vehicles, ../../widgets/home/my_vehicles_section.dart

### Community 91 - "Cloud Functions Scripts"
Cohesion: 0.32
Nodes (7): admin, fs, loadFirebaseToolsRefreshToken(), main(), os, path, writeTemporaryAdcFile()

### Community 92 - "Data Repositories (3)"
Cohesion: 0.25
Nodes (7): _licensePlate, openVehicleBooking, PendingBookingVehicle, _vehicleLabel, ../../models/vehicle.dart, package:flutter/foundation.dart, static String?

### Community 93 - "Widget/Unit Tests (7)"
Cohesion: 0.25
Nodes (7): package:sanayi_app/screens/appointments/customer_conversation_page.dart, package:sanayi_app/screens/booking/appointment_request_page.dart, chatId, main, pumpApp, seedChatAndOpenConversation, seedMechanicAccount

### Community 94 - "Graphify Skill Docs (5)"
Cohesion: 0.29
Nodes (7): /graphify explain flow, LESSONS.md work memory, /graphify path flow, graphify reflect --if-stale command, graphify save-result command, /graphify explain command, /graphify path command

### Community 95 - "Home Widgets (5)"
Cohesion: 0.29
Nodes (6): ../../data/appointment_request_store.dart, build, GreetingBar, onNotificationTap, unreadMessageCount, userName

### Community 96 - "Utilities (2)"
Cohesion: 0.29
Nodes (6): firebase_instances.dart, data, doc, resolveCustomerId, resolveMyBusinessId, uid

### Community 97 - "Mechanic Bulk Upload Script (2)"
Cohesion: 0.33
Nodes (6): admin, db, main(), mechanics, serviceAccount, uploadMechanic()

### Community 98 - "Utilities (3)"
Cohesion: 0.33
Nodes (5): FirebaseAuth, FirebaseFirestore, firebaseAuthInstance, firestoreInstance, package:firebase_auth/firebase_auth.dart

### Community 99 - "Data Repositories (4)"
Cohesion: 0.33
Nodes (5): BookingHistory, _completedMechanicNames, hasCompleted, markCompleted, static final Set

### Community 100 - "Data Repositories (5)"
Cohesion: 0.33
Nodes (5): fetchByBusinessId, fetchByHizmetTuru, _firestore, MechanicDirectoryRepository, ../../models/mechanic.dart

### Community 101 - "Service Categories (5)"
Cohesion: 0.33
Nodes (5): AcClimateCategoryPage, build, _cardSpacing, onServiceSelected, _services

### Community 102 - "Service Categories (6)"
Cohesion: 0.33
Nodes (5): BodyPaintCategoryPage, build, _cardSpacing, onServiceSelected, _services

### Community 103 - "Service Categories (7)"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, ExhaustSystemCategoryPage, onServiceSelected, _services

### Community 104 - "Service Categories (8)"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, OilChangeCategoryPage, onServiceSelected, _services

### Community 105 - "Service Categories (9)"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, onServiceSelected, _services, SuspensionSteeringCategoryPage

### Community 106 - "Service Categories (10)"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, onServiceSelected, _services, TireWheelCategoryPage

### Community 107 - "Service Categories (11)"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, onServiceSelected, _services, TransmissionClutchCategoryPage

### Community 108 - "Home Widgets (6)"
Cohesion: 0.33
Nodes (5): build, onSeeAll, SectionHeader, title, VoidCallback

### Community 109 - "Widgets (misc)"
Cohesion: 0.33
Nodes (5): build, mechanicId, minThreshold, VerifiedJobsBadge, ../mechanic/appointments/data/appointment_repository.dart

### Community 110 - "Graphify Skill Docs (6)"
Cohesion: 0.40
Nodes (5): Step 2.5: Transcribe video/audio flow, Whisper domain-hint prompt, Step 1: Ensure graphify is installed, Step 2.5: Video and audio, Step 2: Detect files

### Community 111 - "Graphify Skill Docs (7)"
Cohesion: 0.40
Nodes (5): graphify.analyze.graph_diff(), Step 4.5: Graph health check, Step 4: Build graph, cluster, analyze, generate outputs, Step 5: Label communities, Step 6: Generate Obsidian vault + HTML

### Community 112 - "Appointment Widgets (2)"
Cohesion: 0.40
Nodes (4): date, now, time, today

### Community 113 - "Mechanic Appointments (13)"
Cohesion: 0.67
Nodes (4): _TypingIndicatorState, _TypingIndicatorState, SingleTickerProviderStateMixin, _TypingIndicator

### Community 114 - "Data Models (3)"
Cohesion: 0.50
Nodes (3): isAvailable, label, TimeSlot

### Community 115 - "Utilities (4)"
Cohesion: 0.50
Nodes (3): mechanicChatId, result, turkishToAscii

## Ambiguous Edges - Review These
- `google_sign_in_web Dependency` → `social_auth.dart googleSignInButton() (referenced, path uncertain)`  [AMBIGUOUS]
  pubspec.yaml · relation: references

## Knowledge Gaps
- **1417 isolated node(s):** `name`, `build`, `build:watch`, `serve`, `shell` (+1412 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1600 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **22 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `google_sign_in_web Dependency` and `social_auth.dart googleSignInButton() (referenced, path uncertain)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `_` connect `Auth Core` to `Utilities (3)`, `Mechanic Profile (2)`, `Mechanic Appointments (12)`, `Data Models`, `Auth Core (2)`, `Data Repositories (3)`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `Mechanic` connect `Search Widgets` to `Customer Appointments (4)`, `Customer Appointments`, `Booking Flow`, `Service Listing Widgets`, `Mechanic Detail Screen`, `Mechanic Auth`, `Data Models`, `Mechanic Profile`, `Service Listing`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `name`, `build`, `build:watch` to the rest of the system?**
  _1417 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Mechanic Appointments` be split into smaller, more focused modules?**
  _Cohesion score 0.022727272727272728 - nodes in this community are weakly interconnected._
- **Should `Mechanic Appointments (2)` be split into smaller, more focused modules?**
  _Cohesion score 0.028985507246376812 - nodes in this community are weakly interconnected._
- **Should `Windows Desktop Runner` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._