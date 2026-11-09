# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

The owner of a single business, doing their own invoicing and paperwork for that one company, mostly on an Android phone. They issue documents to other businesses (B2B).

## Product Purpose

Lets a business owner produce and keep track of their commercial paperwork from a phone: quotations, proforma invoices, purchase orders (LPOs), tax invoices, delivery notes, credit notes and customer statements. Success is a correct, professional document in the customer's hands without needing accounting software or an accountant in the loop.

## Positioning

A single-owner paperwork app built around UAE documents. It combines four things the owner would otherwise have to give up one of: documents in the format UAE customers expect, working without a connection, every document type in one place, and the simplicity and low cost of not running accounting software. Alternatives considered by the owner are Zoho, QuickBooks and Excel.

## Operating Context

- Work mostly happens on an Android phone. The codebase also builds for Windows (MSIX packaging is set up), which is secondary.
- Documents leave the app as PDF or Excel files, shared or printed from the device.
- Data is stored on the device first. Cloud sync (Supabase) and a Google Sheets export are optional, and the app has to stay fully usable without them.
- Documents are linked in a chain: a quotation or proforma can become an invoice, a delivery note is produced from an invoice, a credit note is issued against an invoice, and a customer statement rolls up that customer's invoices and credit notes.

## Capabilities and Constraints

- Tax documents follow UAE VAT conventions: "Tax Invoice" and "Tax Credit Note" titles, supplier and buyer TRN, place of supply, VAT shown separately, amount in words, bank details and a declaration.
- Default currency is AED; USD, EUR and GBP can be selected on invoices.
- Issued credit notes are not edited. A mistake is corrected by voiding, which keeps the number on record.
- Terminology: "client" in code and "customer" on documents; "LPO" for a local purchase order; "TRN" for the tax registration number.
- Payments are not recorded individually: an invoice is either paid or not, and there is no refund record. A credit against a paid invoice stays on the customer's account as a credit balance.
- One business profile per install. There are no team roles or permissions.
- Undecided: the public product name. The code still uses "Flutter Invoice App" and the Android ID `com.example.flutter_invoice_app`.

## Evidence on Hand

- App icon: `assets/images/app_icon.jpg`.
- The owner's own logo and business profile are entered inside the app, not shipped with it.
- There are no customer testimonials, usage numbers, pricing or compliance certifications on hand. Do not invent them, and do not claim UAE tax authority approval.

## Product Principles

- **The paperwork has to be right.** A document that goes to a customer carries legal and tax weight, so correctness comes before speed or looks.
- **The phone is the real workplace.** Every job must be completable on an Android phone, not just viewable there.
- **No connection is a normal day.** Nothing essential may depend on the network.
- **One chain of documents.** Work done on one document carries into the next rather than being typed again.
- **Plain over powerful.** The user is a business owner, not a bookkeeper, so speak in business terms and leave out what accounting software would add.
