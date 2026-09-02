/// Centralized feature flags — compile-time constants, not remote config.
/// Each flag gates a deliberate, currently-off product surface; the gated
/// code, routes, and Firestore fields stay in place and get flipped back on
/// by changing the constant, not by re-adding anything.
library;

/// Disabled pending SEDDK licensing review. This is a permanent product
/// decision until that review completes, not a temporary workaround —
/// SigortaPage and every hizmetTürü:'sigorta' Firestore document remain
/// exactly as they are; this flag only controls whether the category is
/// reachable from the UI. See home_tab.dart, mechanic_login_page.dart.
const bool kSigortaEnabled = false;
