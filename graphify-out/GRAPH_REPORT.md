# Graph Report - sanayi_app  (2026-09-07)

## Corpus Check
- 196 files · ~181,840 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2450 nodes · 3458 edges · 156 communities (125 shown, 25 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 33 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `be6b370c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- mechanic_appointments_screen.dart
- appointment.dart
- FlutterWindow
- appointment_request_page.dart
- customer_conversation_page.dart
- GeneratedPluginRegistrant.swift
- app_theme.dart
- appointment_detail_page.dart
- generate_adaptive_foreground.dart
- mechanic_request_details_page.dart
- mechanic_appointment_details_page.dart
- mechanic_login_page.dart
- mock_data.dart
- mechanic_conversation_page.dart
- login_page.dart
- mechanic.dart
- appointment_calendar_view.dart
- home_tab.dart
- my_vehicles_section.dart
- premium_surface.dart
- main_shell.dart
- search_tab.dart
- mechanic_home_screen.dart
- scripts
- appointments_tab.dart
- mechanic_notifications_screen.dart
- my_application.cc
- appointment_request_store.dart
- win32_window.cpp
- _
- notifications_page.dart
- reviews_page.dart
- package:flutter/material.dart
- appointment_repository.dart
- MechanicRequestDetailsPage
- customer_conversation_list_page.dart
- dummy_appointment.dart
- StatelessWidget
- appointment_request.dart
- main.dart
- service_center_card.dart
- mechanic_detail_page.dart
- booking_test.dart
- MaterialPageRoute
- chat_unread_test.dart
- appointment_negotiation_test.dart
- /graphify command
- package:cloud_firestore/cloud_firestore.dart
- service_category_card.dart
- customer_profile_tab.dart
- mechanic_list_tile.dart
- admin_approval_screen.dart
- all_categories_page.dart
- skeleton_loader.dart
- appointment_card.dart
- premium_hero_header.dart
- sanayi_app pubspec Dependencies (Firebase/Auth stack)
- emergency_help_card.dart
- compilerOptions
- working_hours.dart
- category_list.dart
- request_another_time_sheet.dart
- trust_metric_tile.dart
- appointment_request_card.dart
- Win32Window
- mechanic_profile_screen.dart
- fake_google_sign_in_platform.dart
- MessageHandler
- wWinMain
- mechanic_profile_repository.dart
- List
- category_grid.dart
- chat_repository.dart
- category_card.dart
- verified_trust_badge.dart
- manifest.json
- mechanic_home_page.dart
- sort_filter_bar.dart
- brake_system_category_page.dart
- contact_info_sheet.dart
- mechanic_upload/package.json
- ../../data/mock_data.dart
- Steps 6b-8: Wiki, Neo4j, FalkorDB, SVG, GraphML, MCP, benchmark
- Extraction subagent prompt
- /graphify query flow
- ValueChanged
- index.ts
- VoidCallback
- chat_booking_action_test.dart
- Graphify Knowledge Graph Workflow
- SingleTickerProviderStateMixin
- backfill_hizmet_turu.js
- pending_booking_vehicle.dart
- exhaust_system_category_page.dart
- graphify save-result command
- RegisterPlugins
- identity.dart
- upload_mechanics.js
- admin_repository.dart
- booking_history.dart
- ../../models/mechanic.dart
- IconData
- greeting_bar.dart
- Point
- Size
- _MechanicAppointmentsScreenState
- all_vehicles_page.dart
- _SuggestionSentBannerState
- mechanic_home_screen_test.dart
- ../mechanic/appointments/data/appointment_repository.dart
- Step 2.5: Video and audio
- Step 4.5: Graph health check
- static const
- time_slot.dart
- chat_id.dart
- MainActivity.kt
- mechanic_profile_screen_test.dart
- relative_time.dart
- flutter run Device-Offline Failure (attempt 2)
- RecaptchaVerifier Phone Sign-In Flow
- google_sign_in_button_stub.dart
- iOS LaunchImage Assets
- google_sign_in_button_web.dart
- feature_flags.dart
- category_grid_test.dart
- firebase_options.dart
- transmission_clutch_category_page.dart
- ../../utils/firebase_instances.dart
- _RequestActionBar
- add_claimed_by_uid.js
- macOS App Icon (Default Flutter Logo)
- adaptive_icon_foreground_inset Configuration
- Plus Jakarta Sans Font (SIL OFL License)
- Mesajlar (Messages) Chat Screen Screenshot
- Messages (Chat) Screen - Ahmet Yılmaz Request
- iOS Launch Image (@3x, blank)
- String?
- firebase_instances.dart
- ClaimConflictException
- propose_time_dialog.dart
- google_sign_in_button_stub.dart
- motor_category_page.dart
- oil_change_category_page.dart
- periodic_maintenance_category_page.dart
- package:fake_cloud_firestore/fake_cloud_firestore.dart
- State
- package:firebase_auth_mocks/firebase_auth_mocks.dart
- MechanicHomeScreen
- AppointmentRequestPage
- _TurkishPhoneInputFormatter

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
- **graphify CLI Workflow (query/path/explain/update)** — claude_graphify_query, claude_graphify_path, claude_graphify_explain, claude_graphify_update [EXTRACTED 1.00]
- **Core Build Pipeline (Steps 1-9)** — claude_skills_graphify_skill_step1_ensure_installed, claude_skills_graphify_skill_step2_detect_files, claude_skills_graphify_skill_step3_extract, claude_skills_graphify_skill_step4_build_graph, claude_skills_graphify_skill_step4_5_health_check, claude_skills_graphify_skill_step5_label_communities, claude_skills_graphify_skill_step6_obsidian_html, claude_skills_graphify_skill_step9_manifest_cleanup [EXTRACTED 1.00]
- **Extra Export Formats (Steps 6b-8)** — claude_skills_graphify_references_exports_wiki_export, claude_skills_graphify_references_exports_neo4j_export, claude_skills_graphify_references_exports_falkordb_export, claude_skills_graphify_references_exports_svg_export, claude_skills_graphify_references_exports_graphml_export, claude_skills_graphify_references_exports_mcp_server, claude_skills_graphify_references_exports_token_benchmark [EXTRACTED 1.00]
- **Firebase/Google Sign-In Authentication Stack** — pubspec_dependencies, pubspec_google_sign_in_web, web_index_google_signin_client_id, web_index_recaptcha_container, build_result_kgp_plugin_warning [INFERRED 0.85]
- **Flutter Desktop Runner Build Pattern (Linux/Windows)** — linux_cmakelists_runner_target, linux_runner_cmakelists_runner_executable, windows_cmakelists_runner_target, windows_runner_cmakelists_runner_executable [INFERRED 0.85]
- **Graph Query & Self-Improving Recall Loop** — claude_skills_graphify_references_query_query_flow, claude_skills_graphify_references_query_path_flow, claude_skills_graphify_references_query_explain_flow, claude_skills_graphify_references_query_save_result_command, claude_skills_graphify_references_query_reflect_command [INFERRED 0.85]

## Communities (156 total, 25 thin omitted)

### Community 0 - "mechanic_appointments_screen.dart"
Cohesion: 0.02
Nodes (86): Animation, _acceptRequest, _acceptTimeProposal, appointment, appointmentDate, appointmentId, _appointmentRepository, _appointments (+78 more)

### Community 1 - "appointment.dart"
Cohesion: 0.03
Nodes (68): DateTime get, Duration, appointmentDate, appointmentDateAnchorHourUtc, appointmentId, AppointmentStatus, appointmentTime, buildDummyAppointments (+60 more)

### Community 2 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+5 more)

### Community 3 - "appointment_request_page.dart"
Cohesion: 0.04
Nodes (50): _borderColor, build, _buildChip, _chipHeight, _chipWidth, createState, dateLabel, _dates (+42 more)

### Community 4 - "customer_conversation_page.dart"
Cohesion: 0.04
Nodes (46): _borderRadius, _bubbleColor, build, _ChatBubble, chatId, _chipSpacing, _controller, createState (+38 more)

### Community 5 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, cloud_firestore, Cocoa, firebase_app_check, firebase_auth, firebase_core, Flutter, FlutterAppDelegate (+25 more)

### Community 6 - "app_theme.dart"
Cohesion: 0.04
Nodes (51): AppColors, AppRadius, AppShadows, AppSpacing, AppTextStyles, AppTheme, background, body (+43 more)

### Community 7 - "appointment_detail_page.dart"
Cohesion: 0.11
Nodes (19): AppointmentRequest get, customer_conversation_page.dart, _acceptSuggestion, AppointmentDetailPage, _AppointmentDetailPageState, build, createState, _DetailRow (+11 more)

### Community 8 - "generate_adaptive_foreground.dart"
Cohesion: 0.05
Nodes (43): dart:collection, dart:io, package:image/image.dart, bg, _bgThreshold, counts, file, filledCount (+35 more)

### Community 9 - "mechanic_request_details_page.dart"
Cohesion: 0.05
Nodes (42): appointment_calendar_view.dart, _acceptRequest, _acceptTimeProposal, appointment, _appointments, count, createState, _CustomerInfoCard (+34 more)

### Community 10 - "mechanic_appointment_details_page.dart"
Cohesion: 0.05
Nodes (40): data/appointment_repository.dart, appointment, _AppointmentCard, appointmentDate, appointmentTime, businessId, _buttonHeight, _cardRadius (+32 more)

### Community 11 - "mechanic_login_page.dart"
Cohesion: 0.03
Nodes (61): ../home/mechanic_home_page.dart, _afterSignedIn, batch, build, businessId, _businessNameController, _BusinessOption, _BusinessOptionLabel (+53 more)

### Community 12 - "mock_data.dart"
Cohesion: 0.05
Nodes (38): CustomPainter, allMechanics, allServiceCategories, categories, ekspertizCategories, MockData, otherMechanics, popularMechanics (+30 more)

### Community 13 - "mechanic_conversation_page.dart"
Cohesion: 0.05
Nodes (39): data/chat_message.dart, data/chat_repository.dart, appointment, _bubbleColor, _ChatBubble, chatId, _controller, createState (+31 more)

### Community 14 - "login_page.dart"
Cohesion: 0.05
Nodes (39): ../home/main_shell.dart, _afterSignedIn, _AuthDialog, _AuthDialogState, build, _codeController, _confirmCode, createState (+31 more)

### Community 15 - "mechanic.dart"
Cohesion: 0.05
Nodes (37): bool get, double?, int?, address, businessId, businessName, email, fromFirestore (+29 more)

### Community 16 - "appointment_calendar_view.dart"
Cohesion: 0.05
Nodes (41): data/appointment.dart, appointment, _AppointmentBlock, AppointmentCalendarView, _AppointmentCalendarViewState, appointments, barColor, _borderColor (+33 more)

### Community 17 - "home_tab.dart"
Cohesion: 0.11
Nodes (18): build, _clusterSpacing, HomeTab, _MainServiceCategories, onCategoryTap, _sectionPadding, _showComingSoon, _spacing (+10 more)

### Community 18 - "my_vehicles_section.dart"
Cohesion: 0.06
Nodes (34): deriveVehiclesFromAppointments, licensePlate, modelLabel, seen, sorted, Vehicle, vehicles, _AddVehicleRow (+26 more)

### Community 19 - "premium_surface.dart"
Cohesion: 0.06
Nodes (33): BoxBorder?, Gradient?, _animationDuration, border, borderRadius, build, child, color (+25 more)

### Community 20 - "main_shell.dart"
Cohesion: 0.07
Nodes (29): ../appointments/appointments_tab.dart, ../appointments/customer_conversation_list_page.dart, ../categories/ac_climate_category_page.dart, ../categories/battery_electrical_category_page.dart, ../categories/body_paint_category_page.dart, ../categories/brake_system_category_page.dart, ../categories/exhaust_system_category_page.dart, ../categories/glass_lighting_category_page.dart (+21 more)

### Community 21 - "search_tab.dart"
Cohesion: 0.06
Nodes (33): ../../data/mechanic_directory_repository.dart, Future, build, _controller, createState, dispose, _filteredResults, _future (+25 more)

### Community 22 - "mechanic_home_screen.dart"
Cohesion: 0.03
Nodes (60): ../appointments/mechanic_request_details_page.dart, dart:math, appointmentDate, _appointmentRepository, _appointmentRequestCount, build, businessName, createdAt (+52 more)

### Community 23 - "scripts"
Cohesion: 0.07
Nodes (28): firebase-functions, dependencies, firebase-admin, firebase-functions, devDependencies, jest, ts-jest, @types/jest (+20 more)

### Community 24 - "appointments_tab.dart"
Cohesion: 0.08
Nodes (27): Appointment, appointment, _AppointmentList, AppointmentsTab, _AppointmentsTabState, build, comment, _commentController (+19 more)

### Community 25 - "mechanic_notifications_screen.dart"
Cohesion: 0.08
Nodes (25): ../appointments/data/appointment.dart, ../appointments/data/chat_message.dart, ../appointments/data/chat_repository.dart, ../appointments/mechanic_conversation_page.dart, _buildPendingRequestTile, createState, _customerLabel, _formatChatTime (+17 more)

### Community 26 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 27 - "appointment_request_store.dart"
Cohesion: 0.08
Nodes (25): ChangeNotifier, int get, accept, actionNeededCount, _applyRealAppointment, appointmentRequestFromAccepted, AppointmentRequestStore, _combine (+17 more)

### Community 28 - "win32_window.cpp"
Cohesion: 0.21
Nodes (12): wchar_t, Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_ (+4 more)

### Community 29 - "_"
Cohesion: 0.08
Nodes (25): google_sign_in_button.dart, _, account, autoSignedInCredential, completer, credential, digits, googleSignInAccounts (+17 more)

### Community 30 - "notifications_page.dart"
Cohesion: 0.09
Nodes (21): ../appointments/customer_conversation_page.dart, _acceptSuggestion, chat, createState, _DeclinedRequestCard, dispose, _EmptyState, _firestoreAppointments (+13 more)

### Community 31 - "reviews_page.dart"
Cohesion: 0.08
Nodes (24): ../../data/booking_history.dart, build, count, createState, distribution, _DistributionRow, _filter, _FilterRow (+16 more)

### Community 32 - "package:flutter/material.dart"
Cohesion: 0.14
Nodes (13): build, SectionLabel, text, build, isOpen, OpenStatusBadge, build, VerifiedBadge (+5 more)

### Community 33 - "appointment_repository.dart"
Cohesion: 0.09
Nodes (22): appointment.dart, acceptProposedTime, acceptTimeProposal, AppointmentRepository, _collection, fetchAppointmentById, fetchAppointments, fetchOnTimeCompletionRate (+14 more)

### Community 35 - "customer_conversation_list_page.dart"
Cohesion: 0.10
Nodes (20): chatId, _ConversationRow, createState, _EmptyState, _fillColor, _FilterChip, _filters, _findMechanicByName (+12 more)

### Community 36 - "dummy_appointment.dart"
Cohesion: 0.10
Nodes (20): AppointmentStatus, Color get, _StatusBarColor, AppointmentStatusPresentation, AppointmentStatus, AppointmentStatusPresentation, color, date (+12 more)

### Community 37 - "StatelessWidget"
Cohesion: 0.13
Nodes (18): _AvailableBadge, _DailyScheduleRow, _EmptyTabState, _InfoRow, _NewRequestBadge, _NewRequestCard, _ServiceBadge, _SuggestInfoRow (+10 more)

### Community 38 - "appointment_request.dart"
Cohesion: 0.15
Nodes (12): AppointmentRequestStatus, businessId, customerId, date, id, mechanicName, preferredWindowLabel, proposedDateTime (+4 more)

### Community 39 - "main.dart"
Cohesion: 0.18
Nodes (10): ../../auth/social_auth.dart, dev/dev_mode_launcher.dart, firebase_options.dart, build, initializeApp, initializeGoogleSignIn, main, SanayiApp (+2 more)

### Community 40 - "service_center_card.dart"
Cohesion: 0.09
Nodes (21): _actionsPadding, _background, build, _buttonSpacing, _CenterInfo, color, _gradient, icon (+13 more)

### Community 41 - "mechanic_detail_page.dart"
Cohesion: 0.11
Nodes (18): ../booking/appointment_request_page.dart, build, icon, _InfoCard, mechanic, MechanicDetailPage, _RatingSummaryRow, _showFeedback (+10 more)

### Community 42 - "booking_test.dart"
Cohesion: 0.14
Nodes (16): ElevatedButton, package:sanayi_app/data/pending_booking_vehicle.dart, package:sanayi_app/models/mechanic.dart, package:sanayi_app/screens/categories/tire_wheel_category_page.dart, package:sanayi_app/screens/mechanic_detail/mechanic_detail_page.dart, package:sanayi_app/screens/search/search_tab.dart, package:sanayi_app/widgets/booking/date_strip.dart, main (+8 more)

### Community 43 - "MaterialPageRoute"
Cohesion: 0.11
Nodes (18): _openMechanicDetail, build, build, build, build, _openAppointments, _openNotifications, _openRequestDetails (+10 more)

### Community 44 - "chat_unread_test.dart"
Cohesion: 0.13
Nodes (17): package:flutter_test/flutter_test.dart, package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart, package:sanayi_app/data/appointment_request_store.dart, package:sanayi_app/main.dart, package:sanayi_app/screens/appointments/customer_conversation_list_page.dart, package:sanayi_app/screens/auth/login_page.dart, package:sanayi_app/screens/home/main_shell.dart, package:sanayi_app/screens/notifications/notifications_page.dart (+9 more)

### Community 45 - "appointment_negotiation_test.dart"
Cohesion: 0.11
Nodes (18): package:sanayi_app/mechanic/appointments/appointment_calendar_view.dart, package:sanayi_app/mechanic/appointments/mechanic_request_details_page.dart, RichText, appointmentId, businessId, customerUid, main, mechanicUid (+10 more)

### Community 46 - "/graphify command"
Cohesion: 0.14
Nodes (16): .claude/CLAUDE.md graphify pointer, /graphify add flow, --watch background watcher flow, graphify claude install/uninstall, graphify hook install/uninstall/status, --cluster-only flow, --update incremental re-extraction flow, /graphify add command (+8 more)

### Community 47 - "package:cloud_firestore/cloud_firestore.dart"
Cohesion: 0.17
Nodes (10): package:cloud_firestore/cloud_firestore.dart, package:sanayi_app/screens/home/all_vehicles_page.dart, package:sanayi_app/screens/home/vehicle_repair_category_page.dart, customerUid, main, pumpApp, seedAppointment, add (+2 more)

### Community 48 - "service_category_card.dart"
Cohesion: 0.11
Nodes (17): _arrowButtonSize, build, color, icon, _iconBadgeSize, _iconSize, illustration, onTap (+9 more)

### Community 49 - "customer_profile_tab.dart"
Cohesion: 0.04
Nodes (43): ../../admin/admin_approval_screen.dart, ../../admin/data/admin_repository.dart, DateTime?, chatId, ChatMessage, ChatSummary, createdAt, customerDisplayName (+35 more)

### Community 50 - "mechanic_list_tile.dart"
Cohesion: 0.12
Nodes (16): Mechanic, _avatarBackground, _avatarSize, _borderRadius, build, isOpen, _margin, mechanic (+8 more)

### Community 51 - "admin_approval_screen.dart"
Cohesion: 0.05
Nodes (42): data/admin_mechanic_row.dart, data/admin_repository.dart, _AccessDenied, build, _checkAccess, createState, _directoryRepository, _EmptyState (+34 more)

### Community 52 - "all_categories_page.dart"
Cohesion: 0.12
Nodes (14): build, categories, _controller, createState, dispose, onCategorySelected, _query, title (+6 more)

### Community 53 - "skeleton_loader.dart"
Cohesion: 0.14
Nodes (14): AnimationController, _avatarSize, borderRadius, build, _controller, count, createState, dispose (+6 more)

### Community 54 - "appointment_card.dart"
Cohesion: 0.13
Nodes (14): data/dummy_appointment.dart, appointment, AppointmentCard, _AppointmentCardStyles, build, daysUntil, icon, _InfoLine (+6 more)

### Community 55 - "premium_hero_header.dart"
Cohesion: 0.11
Nodes (17): ../../config/feature_flags.dart, _badgeSize, build, _carIconSize, _circleSize, _decorIconAlpha, _decorIconSize, _gradient (+9 more)

### Community 56 - "sanayi_app pubspec Dependencies (Firebase/Auth stack)"
Cohesion: 0.18
Nodes (14): flutter_lints Analyzer Configuration, Gradle assembleDebug Daemon Crash, Kotlin Gradle Plugin (KGP) Migration Warning, social_auth.dart googleSignInButton() (referenced, path uncertain), Linux Top-Level Build Target (sanayi_app), Linux Flutter Library Build Rules, Linux Runner Executable Target, sanayi_app pubspec Dependencies (Firebase/Auth stack) (+6 more)

### Community 57 - "emergency_help_card.dart"
Cohesion: 0.14
Nodes (13): category_illustrations.dart, build, _CallHelpPill, EmergencyHelpCard, _gradient, _illustrationAlpha, _illustrationSize, onTap (+5 more)

### Community 58 - "compilerOptions"
Cohesion: 0.14
Nodes (13): compileOnSave, compilerOptions, module, noImplicitReturns, noUnusedLocals, outDir, sourceMap, strict (+5 more)

### Community 59 - "working_hours.dart"
Cohesion: 0.14
Nodes (13): current, _dayIndex, _dayOrder, endMinutes, indexOf, isOpenNow, matchesToday, normalized (+5 more)

### Community 60 - "category_list.dart"
Cohesion: 0.20
Nodes (9): EdgeInsets, build, categories, CategoryList, onCategoryTap, padding, _spacing, _tileHeight (+1 more)

### Community 61 - "request_another_time_sheet.dart"
Cohesion: 0.18
Nodes (11): ../booking/time_slot_grid.dart, AppointmentRequest, build, createState, onSubmitted, request, _RequestAnotherTimeSheetContent, _RequestAnotherTimeSheetContentState (+3 more)

### Community 62 - "trust_metric_tile.dart"
Cohesion: 0.15
Nodes (12): Color, build, icon, iconColor, _iconSize, _iconSpacing, label, _labelFontSize (+4 more)

### Community 63 - "appointment_request_card.dart"
Cohesion: 0.17
Nodes (11): AppointmentRequestCard, build, color, icon, _InfoRow, label, request, _StatusPill (+3 more)

### Community 64 - "Win32Window"
Cohesion: 0.20
Nodes (14): RECT, OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate (+6 more)

### Community 65 - "mechanic_profile_screen.dart"
Cohesion: 0.10
Nodes (20): ../appointments/data/appointment_repository.dart, data/mechanic_profile.dart, data/mechanic_profile_repository.dart, build, createState, fallback, _fallbackMechanic, icon (+12 more)

### Community 66 - "fake_google_sign_in_platform.dart"
Cohesion: 0.17
Nodes (11): GoogleSignInPlatform, attemptLightweightAuthentication, authenticate, authorizationRequiresUserInteraction, clientAuthorizationTokensForScopes, disconnect, FakeGoogleSignInPlatform, init (+3 more)

### Community 67 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 68 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 69 - "mechanic_profile_repository.dart"
Cohesion: 0.29
Nodes (6): fetchProfile, fetchRepeatCustomerCount, fetchRepeatCustomerRate, _firestore, MechanicProfileRepository, mechanic_profile.dart

### Community 70 - "List"
Cohesion: 0.10
Nodes (18): formatFullDate, isSameDay, _monthFull, _weekdayFull, _weekdayShort, build, dates, DateStrip (+10 more)

### Community 71 - "category_grid.dart"
Cohesion: 0.18
Nodes (10): category_card.dart, build, categories, CategoryGrid, _gridSpacing, _maxColumns, _minColumns, onCategoryTap (+2 more)

### Community 72 - "chat_repository.dart"
Cohesion: 0.18
Nodes (10): chat_message.dart, dart:async, ChatRepository, _firestore, markMessagesRead, _messagesRef, sendMessage, watchChats (+2 more)

### Community 73 - "category_card.dart"
Cohesion: 0.08
Nodes (24): ../common/premium_surface.dart, _background, build, category, CategoryCard, _iconSize, _iconSpacing, _liftScale (+16 more)

### Community 74 - "verified_trust_badge.dart"
Cohesion: 0.18
Nodes (10): _backgroundAlpha, _borderAlpha, _borderRadius, build, _fontSize, _horizontalPadding, _iconSize, _iconSpacing (+2 more)

### Community 75 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 76 - "mechanic_home_page.dart"
Cohesion: 0.22
Nodes (9): ../appointments/mechanic_appointments_screen.dart, build, createState, MechanicHomePage, _MechanicHomePageState, _screens, _selectedIndex, mechanic_home_screen.dart (+1 more)

### Community 77 - "sort_filter_bar.dart"
Cohesion: 0.17
Nodes (12): build, _FilterPill, label, onOpenOnlyChanged, onSortChanged, onTap, openOnly, selected (+4 more)

### Community 78 - "brake_system_category_page.dart"
Cohesion: 0.33
Nodes (5): BrakeSystemCategoryPage, build, _cardSpacing, onServiceSelected, _services

### Community 79 - "contact_info_sheet.dart"
Cohesion: 0.22
Nodes (9): build, _ContactInfoSheetContent, _ContactInfoSheetContentState, createState, dispose, _kvkkAccepted, _nameController, _phoneController (+1 more)

### Community 80 - "mechanic_upload/package.json"
Cohesion: 0.20
Nodes (9): dependencies, firebase-admin, description, firebase-admin, name, private, scripts, upload (+1 more)

### Community 81 - "../../data/mock_data.dart"
Cohesion: 0.28
Nodes (7): ../categories/all_categories_page.dart, ../../data/mock_data.dart, build, EkspertizPage, build, SigortaPage, ../service_listing/service_listing_page.dart

### Community 82 - "Steps 6b-8: Wiki, Neo4j, FalkorDB, SVG, GraphML, MCP, benchmark"
Cohesion: 0.22
Nodes (9): Step 7a: FalkorDB export, Step 7c: GraphML export, Step 7d: MCP stdio server, Step 7: Neo4j export, Step 7b: SVG export, Step 8: Token reduction benchmark, Step 6b: Wiki export, Step 9: Save manifest, update cost tracker, clean up (+1 more)

### Community 83 - "Extraction subagent prompt"
Cohesion: 0.28
Nodes (9): Confidence score rubric, Hyperedge rule, Node ID format rule, Semantic similarity rule, Extraction subagent prompt, Part A: Structural (AST) extraction, Part B: Semantic extraction (subagents), Part C: Merge AST + semantic (+1 more)

### Community 84 - "/graphify query flow"
Cohesion: 0.22
Nodes (9): GitHub clone flow (single/multi repo), graphify merge-graphs command, Multi-subfolder / monorepo merge flow, BFS traversal mode, DFS traversal mode, /graphify query flow, Step 0: Constrained query expansion, /graphify query command (+1 more)

### Community 85 - "ValueChanged"
Cohesion: 0.11
Nodes (15): BodyPaintCategoryPage, build, _cardSpacing, onServiceSelected, _services, build, _cardSpacing, onServiceSelected (+7 more)

### Community 86 - "index.ts"
Cohesion: 0.44
Nodes (6): updateRepeatCustomerRates, writeRepeatCustomerRate(), CompletedAppointment, computeRepeatCustomerRates(), fetchCompletedAppointments(), RepeatCustomerRateResult

### Community 87 - "VoidCallback"
Cohesion: 0.13
Nodes (13): build, onSeeAll, SectionHeader, title, build, _CircleIconButton, DetailActionBar, icon (+5 more)

### Community 88 - "chat_booking_action_test.dart"
Cohesion: 0.18
Nodes (10): package:sanayi_app/screens/appointments/customer_conversation_page.dart, package:sanayi_app/screens/booking/appointment_request_page.dart, package:sanayi_app/utils/firebase_instances.dart, chatId, main, pumpApp, seedChatAndOpenConversation, seedMechanicAccount (+2 more)

### Community 89 - "Graphify Knowledge Graph Workflow"
Cohesion: 0.25
Nodes (8): Graphify Knowledge Graph Workflow, graphify explain command, graphify-out/graph.json, graphify path command, graphify query command, graphify-out/GRAPH_REPORT.md, graphify update command, graphify-out/wiki/index.md

### Community 90 - "SingleTickerProviderStateMixin"
Cohesion: 0.67
Nodes (4): _TypingIndicatorState, _TypingIndicatorState, SingleTickerProviderStateMixin, _TypingIndicator

### Community 91 - "backfill_hizmet_turu.js"
Cohesion: 0.32
Nodes (7): admin, fs, loadFirebaseToolsRefreshToken(), main(), os, path, writeTemporaryAdcFile()

### Community 92 - "pending_booking_vehicle.dart"
Cohesion: 0.25
Nodes (7): _licensePlate, openVehicleBooking, PendingBookingVehicle, _vehicleLabel, ../../models/vehicle.dart, package:flutter/foundation.dart, static String?

### Community 93 - "exhaust_system_category_page.dart"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, ExhaustSystemCategoryPage, onServiceSelected, _services

### Community 94 - "graphify save-result command"
Cohesion: 0.29
Nodes (7): /graphify explain flow, LESSONS.md work memory, /graphify path flow, graphify reflect --if-stale command, graphify save-result command, /graphify explain command, /graphify path command

### Community 96 - "identity.dart"
Cohesion: 0.29
Nodes (6): firebase_instances.dart, data, doc, resolveCustomerId, resolveMyBusinessId, uid

### Community 97 - "upload_mechanics.js"
Cohesion: 0.13
Nodes (19): admin, db, main(), { mechanicChatId }, serviceAccount, mechanicChatId(), TURKISH_TO_ASCII, admin (+11 more)

### Community 98 - "admin_repository.dart"
Cohesion: 0.29
Nodes (6): admin_mechanic_row.dart, AdminRepository, fetchAllMechanicAccounts, _firestore, isCurrentUserAdmin, setMechanicVerified

### Community 99 - "booking_history.dart"
Cohesion: 0.33
Nodes (5): BookingHistory, _completedMechanicNames, hasCompleted, markCompleted, static final Set

### Community 100 - "../../models/mechanic.dart"
Cohesion: 0.29
Nodes (6): FirebaseFirestore, fetchByBusinessId, fetchByHizmetTuru, _firestore, MechanicDirectoryRepository, ../../models/mechanic.dart

### Community 101 - "IconData"
Cohesion: 0.12
Nodes (14): IconData, icon, label, ServiceCategory, subtitle, build, icon, label (+6 more)

### Community 102 - "greeting_bar.dart"
Cohesion: 0.29
Nodes (6): ../../data/appointment_request_store.dart, build, GreetingBar, onNotificationTap, unreadMessageCount, userName

### Community 103 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 104 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 106 - "all_vehicles_page.dart"
Cohesion: 0.25
Nodes (7): ../../data/pending_booking_vehicle.dart, AllVehiclesPage, build, onCategoryTap, _rowSpacing, vehicles, ../../widgets/home/my_vehicles_section.dart

### Community 108 - "mechanic_home_screen_test.dart"
Cohesion: 0.14
Nodes (13): Badge, package:sanayi_app/mechanic/home/mechanic_home_screen.dart, package:sanayi_app/theme/app_theme.dart, package:sanayi_app/widgets/common/premium_surface.dart, RawImage, businessId, daysFromNow, main (+5 more)

### Community 109 - "../mechanic/appointments/data/appointment_repository.dart"
Cohesion: 0.33
Nodes (5): build, mechanicId, minThreshold, VerifiedJobsBadge, ../mechanic/appointments/data/appointment_repository.dart

### Community 110 - "Step 2.5: Video and audio"
Cohesion: 0.40
Nodes (5): Step 2.5: Transcribe video/audio flow, Whisper domain-hint prompt, Step 1: Ensure graphify is installed, Step 2.5: Video and audio, Step 2: Detect files

### Community 111 - "Step 4.5: Graph health check"
Cohesion: 0.40
Nodes (5): graphify.analyze.graph_diff(), Step 4.5: Graph health check, Step 4: Build graph, cluster, analyze, generate outputs, Step 5: Label communities, Step 6: Generate Obsidian vault + HTML

### Community 112 - "static const"
Cohesion: 0.09
Nodes (22): AcClimateCategoryPage, build, _cardSpacing, onServiceSelected, _services, BatteryElectricalCategoryPage, build, _cardSpacing (+14 more)

### Community 114 - "time_slot.dart"
Cohesion: 0.50
Nodes (3): isAvailable, label, TimeSlot

### Community 115 - "chat_id.dart"
Cohesion: 0.50
Nodes (3): mechanicChatId, result, turkishToAscii

### Community 117 - "mechanic_profile_screen_test.dart"
Cohesion: 0.25
Nodes (7): package:sanayi_app/mechanic/profile/mechanic_profile_screen.dart, businessId, main, pumpScreen, seedCompletedAppointment, seedProfile, uid

### Community 125 - "category_grid_test.dart"
Cohesion: 0.22
Nodes (8): package:sanayi_app/screens/categories/ac_climate_category_page.dart, package:sanayi_app/screens/categories/motor_category_page.dart, package:sanayi_app/screens/categories/periodic_maintenance_category_page.dart, package:sanayi_app/screens/home/home_tab.dart, package:sanayi_app/screens/service_listing/service_listing_page.dart, main, openVehicleRepair, pumpApp

### Community 126 - "firebase_options.dart"
Cohesion: 0.22
Nodes (8): android, DefaultFirebaseOptions, ios, macos, web, windows, package:firebase_core/firebase_core.dart, static const FirebaseOptions

### Community 127 - "transmission_clutch_category_page.dart"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, onServiceSelected, _services, TransmissionClutchCategoryPage

### Community 128 - "../../utils/firebase_instances.dart"
Cohesion: 0.33
Nodes (5): build, DevModeLauncher, ../mechanic/auth/mechanic_login_page.dart, ../screens/auth/login_page.dart, ../../utils/firebase_instances.dart

### Community 130 - "add_claimed_by_uid.js"
Cohesion: 0.33
Nodes (4): admin, db, SCRIPT_UPLOADED_DOC_IDS, serviceAccount

### Community 144 - "firebase_instances.dart"
Cohesion: 0.40
Nodes (4): FirebaseAuth, firebaseAuthInstance, firestoreInstance, package:firebase_auth/firebase_auth.dart

### Community 146 - "propose_time_dialog.dart"
Cohesion: 0.40
Nodes (4): date, now, time, today

### Community 148 - "motor_category_page.dart"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, MotorCategoryPage, onServiceSelected, _services

### Community 149 - "oil_change_category_page.dart"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, OilChangeCategoryPage, onServiceSelected, _services

### Community 150 - "periodic_maintenance_category_page.dart"
Cohesion: 0.33
Nodes (5): build, _cardSpacing, onServiceSelected, PeriodicMaintenanceCategoryPage, _services

### Community 151 - "package:fake_cloud_firestore/fake_cloud_firestore.dart"
Cohesion: 0.33
Nodes (5): package:fake_cloud_firestore/fake_cloud_firestore.dart, package:sanayi_app/utils/chat_id.dart, package:sanayi_app/widgets/service_listing/service_center_card.dart, main, pumpCard

### Community 152 - "State"
Cohesion: 0.13
Nodes (22): AdminApprovalScreen, _AdminApprovalScreenState, _TypingIndicator, _BusinessPickerDialog, _BusinessPickerDialogState, _MechanicAuthDialog, _MechanicAuthDialogState, MechanicLoginPage (+14 more)

### Community 153 - "package:firebase_auth_mocks/firebase_auth_mocks.dart"
Cohesion: 0.33
Nodes (5): package:firebase_auth_mocks/firebase_auth_mocks.dart, package:sanayi_app/mechanic/home/mechanic_home_page.dart, main, openMechanicRegisterDialog, submitAndWaitForNavigation

## Ambiguous Edges - Review These
- `social_auth.dart googleSignInButton() (referenced, path uncertain)` → `google_sign_in_web Dependency`  [AMBIGUOUS]
  pubspec.yaml · relation: references

## Knowledge Gaps
- **1517 isolated node(s):** `name`, `build`, `build:watch`, `serve`, `shell` (+1512 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1716 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `social_auth.dart googleSignInButton() (referenced, path uncertain)` and `google_sign_in_web Dependency`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `_` connect `_` to `../../utils/firebase_instances.dart`, `chat_repository.dart`, `mechanic.dart`, `firebase_instances.dart`, `google_sign_in_button_stub.dart`, `pending_booking_vehicle.dart`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Why does `AppointmentRequest` connect `request_another_time_sheet.dart` to `notifications_page.dart`, `appointment_request_card.dart`, `appointment_request.dart`, `appointment_detail_page.dart`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Why does `MechanicProfile` connect `mechanic.dart` to `mechanic_profile_screen.dart`, `mechanic_home_screen.dart`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `name`, `build`, `build:watch` to the rest of the system?**
  _1517 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `mechanic_appointments_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022988505747126436 - nodes in this community are weakly interconnected._
- **Should `appointment.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.028985507246376812 - nodes in this community are weakly interconnected._