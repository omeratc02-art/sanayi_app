import {
  isNewlyAwaitingVerification,
  buildCompletionReminderNotification,
  AWAITING_VERIFICATION_STATUS,
} from "./completionReminder";

describe("isNewlyAwaitingVerification", () => {
  it("is true when tamamlanmaDurumu transitions from beklemede to usta_onayladi_bekleniyor", () => {
    const before = { tamamlanmaDurumu: "beklemede" };
    const after = { tamamlanmaDurumu: AWAITING_VERIFICATION_STATUS };

    expect(isNewlyAwaitingVerification(before, after)).toBe(true);
  });

  it("is false when the document already sat in usta_onayladi_bekleniyor and an unrelated field changed", () => {
    const before = { tamamlanmaDurumu: AWAITING_VERIFICATION_STATUS, müşteriNotu: "eski not" };
    const after = { tamamlanmaDurumu: AWAITING_VERIFICATION_STATUS, müşteriNotu: "yeni not" };

    expect(isNewlyAwaitingVerification(before, after)).toBe(false);
  });

  it("is false for a transition into a different tamamlanmaDurumu value", () => {
    const before = { tamamlanmaDurumu: AWAITING_VERIFICATION_STATUS };
    const after = { tamamlanmaDurumu: "dogrulanmis_tamamlandi" };

    expect(isNewlyAwaitingVerification(before, after)).toBe(false);
  });

  it("is true even with no before document at all — a document created directly in this state still fires", () => {
    const after = { tamamlanmaDurumu: AWAITING_VERIFICATION_STATUS };

    // Only an *already*-awaiting-verification document being re-touched
    // should be suppressed — a brand-new one starting in this state has
    // never fired a reminder yet, so it must not be silently skipped.
    expect(isNewlyAwaitingVerification(undefined, after)).toBe(true);
  });

  it("is false when the document was deleted (no after data)", () => {
    const before = { tamamlanmaDurumu: "beklemede" };

    expect(isNewlyAwaitingVerification(before, undefined)).toBe(false);
  });

  it("is false when neither before nor after ever reached the awaiting-verification state", () => {
    const before = { tamamlanmaDurumu: "beklemede" };
    const after = { tamamlanmaDurumu: "kabul edildi" };

    expect(isNewlyAwaitingVerification(before, after)).toBe(false);
  });
});

describe("buildCompletionReminderNotification", () => {
  it("returns the real Turkish title/body, not a placeholder", () => {
    const notification = buildCompletionReminderNotification();

    expect(notification.title).toBe("Randevunuz tamamlandı");
    expect(notification.body).toBe("Onayınızı bekliyoruz — randevunuzu kontrol edin.");
  });
});
