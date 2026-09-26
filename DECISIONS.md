# Decisions

Append-only log of decisions that carried a real trade-off (chose X, rejected Y, why).

## 2026-09-26 — Visual identity: "Neon Night on the Strip" (redesign)

**Chose:** reskin the explorer from the current *desert atlas* identity (warm beige
paper, charcoal ink, terra-cotta red, light mode) to a **classic neon/retro Las
Vegas Strip** identity — near-black night sky, warm-white text, hot-pink / cyan /
gold / purple neon accents, Monoton neon-tube display font on the wordmark & hero,
glow + marquee-bulb treatments on the chrome.

**Scope:** visual reskin only. Page structure, navigation, data pipeline, and IA
are unchanged. No migration off Streamlit.

**Rejected:**
- *Keep the desert-atlas identity.* It's clean and legible but doesn't answer the
  brief ("encapsulate a Las Vegas Strip experience") and is less memorable for a
  recruiter-facing portfolio piece.
- *Modern-luxury-Strip or maximalist-casino aesthetics.* Neon/retro ties directly
  to the app's "Elvis" name (Elvis-era Vegas) and reads unmistakably as "the Strip"
  without the restraint of luxury-minimal or the noise of maximalism.
- *Migrating the frontend off Streamlit* (e.g. Next.js over DuckDB) for full
  creative control. Far larger effort; the token-driven Streamlit design already
  centralizes ~80% of the look, so a reskin captures most of the value cheaply.
- *Full experiential "walk down the Strip" IA redesign.* Higher ambition but higher
  risk to the data legibility that a portfolio piece depends on.

**Governing principle — "flash on the chrome, calm in the data":** neon and the
display font are confined to the marquee zone (hero, wordmark, section labels,
collection cards, link/hover states). The data zone (charts, maps, tables, metrics)
stays a calm low-chroma dark surface with neon only as accent, so *legibility wins*
wherever flash and readability conflict (explicit priority set by Evan).

**Font:** Monoton (neon-tube) for display, chosen over Bungee (signage) and a
script face (Elvis-era). Restricted to large display type only; body stays DM Sans,
mono labels stay Space Mono — both kept for readability.

**Consequence:** the recent "dark session contrast" work (commits fixing the CSS
that *forced* a light palette in dark browser sessions) is inverted by this change —
the app now embraces dark. Those overrides in `explorer.css` are removed/reversed.
