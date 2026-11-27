# Individual Learner Division — Delivery Process

## Goal
Complete the individual learner journey end-to-end before organisation work.

## Sequence
1. Establish branch, database and environment baseline. Verify existing implementation rather than assuming milestone labels mean finished work.
2. Validate homepage, catalogue, course detail, public curriculum preview and pricing.
3. Validate signup, authentication and recovery states.
4. Validate enrolment and access transitions.
5. Validate dashboard, lessons, resources, progress, assessments and completion.
6. Validate badges/certificates and learner communications.
7. Run full journeys with synthetic learners and courses.
8. Fix UX and functional gaps; publish a preview for review.
9. Close with the learner security/privacy gate. Organisation work does not begin until sign-off.

## Required journey
Anonymous visitor discovers a course and understands outcomes, structure and price; creates an account and confirms email; enrols in a free course or follows the paid-course path without premature access; enters dashboard and opens only enrolled materials; completes a lesson and sees accurate progress; attempts an assessment graded server-side; meets completion criteria and receives a valid badge/certificate; logs out, returns, resets password and recovers access.

## Rules
- Use synthetic records in development and screenshots.
- Public curriculum metadata is not lesson content.
- Keep answer keys and grading logic server-side.
- Never trust client-submitted progress, completion, price or payment status.
- Do not call a feature done until tested in the running preview.
- Record scope changes in the decision log.

## Handoff
Provide preview walkthrough, test evidence, open issues and signed security-gate report.
