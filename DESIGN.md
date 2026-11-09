---
name: Flutter Invoice App
description: A whole office's paperwork, tidy and always in your pocket.
colors:
  primary: "#00696D"
  primary-seed: "#006064"
  on-primary: "#FFFFFF"
  tertiary: "#4E5F7D"
  error: "#BA1A1A"
  surface: "#FFFFFF"
  page-wash: "#F5F5F5"
  field-fill: "#FAFAFA"
  ink: "#161D1D"
  ink-muted: "#3F4949"
  hairline: "#BEC8C9"
  status-paid: "#4CAF50"
  status-pending: "#FF9800"
  status-info: "#2196F3"
  status-danger: "#F44336"
  status-accent: "#9C27B0"
  primary-dark: "#80D4D9"
  surface-dark: "#0E1415"
  ink-dark: "#DDE4E4"
typography:
  headline:
    fontFamily: "Outfit, sans-serif"
    fontSize: "24px"
    fontWeight: 700
  section-title:
    fontFamily: "Outfit, sans-serif"
    fontSize: "20px"
    fontWeight: 700
  card-title:
    fontFamily: "Outfit, sans-serif"
    fontSize: "17px"
    fontWeight: 700
  body:
    fontFamily: "Outfit, sans-serif"
    fontSize: "16px"
    fontWeight: 400
  meta:
    fontFamily: "Outfit, sans-serif"
    fontSize: "13px"
    fontWeight: 400
  badge:
    fontFamily: "Outfit, sans-serif"
    fontSize: "10px"
    fontWeight: 700
    letterSpacing: "0.5px"
  figure:
    fontFamily: "Outfit, sans-serif"
    fontSize: "18px"
    fontWeight: 900
  figure-total:
    fontFamily: "Outfit, sans-serif"
    fontSize: "24px"
    fontWeight: 900
rounded:
  badge: "8px"
  icon-chip: "12px"
  control: "16px"
  floating: "20px"
  card: "24px"
  shell: "32px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  2xl: "32px"
  3xl: "40px"
components:
  button-elevated:
    backgroundColor: "{colors.primary-seed}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.control}"
    padding: "16px 32px"
  button-fab:
    rounded: "{rounded.floating}"
  input-field:
    backgroundColor: "{colors.field-fill}"
    rounded: "{rounded.control}"
    padding: "16px 20px"
  card-list:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "{spacing.lg}"
  icon-tile:
    rounded: "{rounded.control}"
    padding: "{spacing.sm}"
  status-badge:
    typography: "{typography.badge}"
    rounded: "{rounded.badge}"
    padding: "4px 10px"
  form-section:
    backgroundColor: "{colors.surface}"
    rounded: "0px"
    padding: "24px 16px"
  totals-panel:
    rounded: "{rounded.card}"
    padding: "{spacing.xl}"
---

# Design System: Flutter Invoice App

## Overview

**Creative North Star: "The Pocket Back Office"**

This is a whole office's paperwork, tidy and always in the owner's pocket. The system is calm and tidy: white surfaces on a barely tinted page, one deep teal for anything that acts, and quiet hairlines doing the work that shadows do elsewhere. Nothing competes with the documents and the figures, which are the reason anyone opened the app.

Controls are soft and sure-footed. Corners are generously rounded, fields are filled rather than outlined, and touch targets are sized for a thumb on a phone. Density is moderate: a list card holds a customer, a document number and an amount, and each screen stays one clear job.

The app is built on Material 3 and themed from a single teal seed, with Outfit as the only typeface. It follows the device's light or dark setting.

**Key Characteristics:**
- One teal voice on white, with colour tints reserved for status and meaning.
- Hairline borders and spacing separate surfaces; shadows barely register.
- Soft, large shapes sized for thumbs.
- Money is always the heaviest text on the card.
- Material components, themed rather than replaced.

## Colors

A restrained teal-on-white palette, with a small set of standard Material hues kept for status.

### Primary
- **Gulf Teal** (primary): every main action, selected navigation, section icons and focus. It is the only colour that means "you can act here".
- **Gulf Teal Seed** (primary-seed): the source colour the palette is generated from. It also appears directly on elevated buttons and the focused field border, where it reads as the same teal.

### Tertiary
- **Slate Blue** (tertiary): marks secondary document types such as proforma and credit note icons, and the "Credited" line on invoice cards.

### Neutral
- **Ledger White** (surface): cards, form panels and the main content panel.
- **Page Wash** (page-wash): applied at 30% opacity behind forms, the dashboard and the sidebar, so white panels lift off the page without a shadow.
- **Field Fill** (field-fill): the resting background of text fields.
- **Office Ink** (ink): primary text.
- **Muted Ink** (ink-muted): metadata such as document numbers, dates and field captions.
- **Hairline** (hairline): applied at 20% opacity for card and panel borders.

### Status
- **Paid Green** (status-paid), **Pending Amber** (status-pending), **Info Blue** (status-info), **Danger Red** (status-danger), **Report Purple** (status-accent): standard Material hues for document status, dashboard stat tiles and warnings.
- **Error Red** (error): form errors and irreversible actions such as voiding or overwriting data.

Dark theme is generated from the same seed: Pale Gulf Teal (primary-dark) on Night Surface (surface-dark) with Pale Ink (ink-dark). Fields there are white at 5% opacity and card borders white at 10%.

**The One Voice Rule.** Gulf Teal is the only colour that signals action. Status hues describe a state and are never used for a button that isn't destructive.

**The Tint Not Fill Rule.** Coloured backgrounds are the hue at 5% to 10% opacity behind an icon or badge. Solid colour is for the primary action alone.

## Typography

**Body Font:** Outfit (loaded through Google Fonts, applied to the whole Material text theme)

**Character:** A single geometric sans. Its round forms match the soft shapes, and hierarchy comes from weight and size rather than a second typeface.

### Hierarchy
- **Headline** (headline): dashboard page title and the grand total on a form.
- **Section Title** (section-title): headings inside a screen, such as "Items" or "Financial Overview".
- **Card Title** (card-title): the customer name on a list card.
- **Body** (body): form values and general text.
- **Meta** (meta): document number and date lines, in Muted Ink.
- **Badge** (badge): uppercase status labels.
- **Figure** (figure): amounts on list cards.
- **Figure Total** (figure-total): the total on a document form, in Gulf Teal.

Sizes are logical pixels, which Flutter scales with the device's font-size setting.

**The Heaviest Is Money Rule.** Amounts carry the heaviest weight (900) on the screen. Bold (700) is for titles, and nothing outranks a figure on a card.

## Layout

Screens are single-column on phones, with 24px padding on lists and the dashboard, 16px between list cards, 32px between dashboard sections and 16px from a section title to its content.

Forms are capped at a 1000px content width and centred. Inside a form section, fields sit in one column up to 600px and two columns above it. Dashboard stat tiles run two across on phones and four above 600px.

Navigation changes at a shortest side of 600px. Below it, a bottom navigation bar shows Home, Invoices, Quotes and Menu, and the Menu screen lists everything else. At or above it, a 100px left sidebar sits beside a content panel with rounded left corners.

**The Thumb First Rule.** The phone layout is the real layout. Wider screens rearrange the same content and never hold features the phone lacks.

## Elevation & Depth

The system is flat. Surfaces separate through a hairline border and the tinted page behind them. App bars are transparent with no elevation, including when content scrolls beneath them. List cards carry an ambient shadow so faint it reads as softness rather than height. The floating action button is the only element with visible lift.

### Shadow Vocabulary
- **Card Breath** (black at 2% opacity, 10px blur, 4px down): list cards only.
- **Floating Lift** (Material elevation 4): the floating action button.

**The Hairline Rule.** If two surfaces need separating, use a hairline or a gap before reaching for a shadow.

## Shapes

Corners follow one soft scale tied to size: small badges, then icon chips, then controls and icon tiles, then floating elements, then cards. The larger the element, the rounder the corner.

The exception is deliberate: form sections are square-cornered bands that run edge to edge on phones, so a long form reads as one continuous sheet. The rounded totals panel below them closes the form.

## Components

### Buttons
Soft and sure-footed.
- **Filled with icon:** the primary action in a form's app bar, such as Save or Issue, in the Material pill shape on Gulf Teal.
- **Elevated:** Gulf Teal Seed with white text and control-radius corners, flat at rest.
- **Text:** low-priority actions such as "Add Item" or "Clear All".
- **Filled tonal icon:** a compact secondary action beside a field.
- **Floating action button:** extended with a bold label and floating-radius corners. One per screen, for the screen's main creation action.
- **Destructive confirm:** a filled button in Error Red inside the confirmation dialog.

### Chips
- **Choice chips:** single selection, such as statement date ranges.
- **Action chips:** one-tap suggestions that fill a field, such as credit note reasons.

### Cards / Containers
- **List card:** icon tile, then customer name over a meta line, then the amount over a status badge on the right. White with card-radius corners, a hairline border and Card Breath.
- **Stat tile:** tinted icon chip, muted label and a bold figure that scales down to fit. Flat with a hairline border.
- **Form section:** an icon and bold title above a square white band with hairline borders.
- **Totals panel:** Gulf Teal at 5% opacity with a 10% border, card-radius corners, label rows and a Figure Total.

### Inputs / Fields
- **Style:** filled with Field Fill, borderless at rest, control-radius corners.
- **Focus:** a 1.5px Gulf Teal Seed border appears.
- **Error:** Material error styling. On narrow per-line fields, the field is only marked and the message sits under the line's description.

### Status Badge
Uppercase Badge text in the status hue on a 10% tint of itself, badge-radius corners.

### Icon Tile
A 24px outlined Material icon in its role colour on a 5% tint of that colour, control-radius corners.

### Navigation
- **Phone:** Material navigation bar with outlined icons that fill when selected.
- **Desktop and tablet:** a slim sidebar with a stacked icon and small label, teal and bold when selected, grey otherwise.

### Feedback
Snackbars for transient results and validation prompts. Alert dialogs only for decisions that must interrupt, such as irreversible actions.

Motion is Material's default page and state transitions; the app has no authored motion of its own.

## Do's and Don'ts

### Do:
- **Do** use Gulf Teal for the one main action on a screen and let everything else stay quiet.
- **Do** build list screens from the list card anatomy: icon tile, customer, meta line, amount, status badge.
- **Do** build forms from form sections, capped at 1000px, and end document forms with the totals panel.
- **Do** set money at weight 900 and pass the document's own currency to the formatter.
- **Do** use Material components and theme roles rather than building equivalents.
- **Do** use a darker shade of the status hue on new badges (700 or deeper), because the base green and amber on their own tint reach only about 2:1 to 2.5:1 contrast at 10px.
- **Do** check new screens at phone width first.

### Don't:
- **Don't** add heavier shadows or lift to cards; separation comes from hairlines and spacing.
- **Don't** fill large areas with status colours; they stay as 5% to 10% tints behind icons and badges.
- **Don't** add a second typeface.
- **Don't** add iOS-style controls; the app follows Material on every platform it ships to.
- **Don't** use a floating action button for anything except the screen's main creation action.
