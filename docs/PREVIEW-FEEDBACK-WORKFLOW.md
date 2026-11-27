# Kaizora Preview Feedback Workflow

**Status:** Product requirement; implementation pending  
**Last updated:** 2026-11-24

## Goal

Let the product owner and authorised reviewers submit suggestions or bug reports from any preview route, or submit general ideas when no preview is open. Feedback must retain enough context to reproduce the issue without exposing learner data.

## Entry points

1. A persistent, small “Send feedback” control on preview builds, accessible from any route.
2. A preview-specific action that automatically attaches preview URL, branch/session/build identifier and current route.
3. A general feedback route for ideas not tied to a preview.

## Submission fields

- Category: bug, usability, content, accessibility, security/privacy or feature request.
- Short title and description.
- Expected result and actual result, where relevant.
- Automatically captured preview URL, route, branch/session/build context.
- Device and viewport where available.
- Optional screenshot/attachment, with a warning not to include passwords, tokens or real learner records.
- Priority/blocker flag.
- Submitter identity only when needed for follow-up.

## Workflow states

New → Triaged → Planned → In progress → Ready for review → Verified.

Declined and Deferred are terminal outcomes that require a short rationale. A report is not Verified until the implementation is checked in a new preview.

## Privacy and access

- Store submissions privately. Do not create a public unauthenticated feedback feed.
- Only authorised project reviewers can view feedback.
- Security/privacy submissions are restricted to a smaller reviewer group.
- Never include secrets, payment details, full learner records or unnecessary PII in reports.
- Do not automatically send messages to external parties.
- Preserve original submission text and attachments; add triage notes separately.

## Acceptance criteria

- Submission works from any preview route.
- Preview context is attached automatically.
- General suggestions work without a preview.
- The submitter receives a confirmation/reference.
- Feedback is not publicly enumerable.
- Reviewer access is server-authorised.
- Sensitive reports are access-restricted.
- Feedback cannot be used to retrieve another user's submissions.
- The original report links to the implementation issue/PR and verification preview.

## Implementation note

Do not use browser localStorage as the authoritative feedback store. It is acceptable only for temporary unsent draft text. Persist submissions through an authenticated server-side endpoint and a private database table with explicit RLS. Until that backend is implemented and tested, the feedback control must not claim that a submission has been saved.
