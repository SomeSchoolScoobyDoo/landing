# Step 7: Lesson Delivery, Progress, and Protected Resources

## Scope

Step 7 adds the database and learner-facing foundation for modules, lessons, learner progress, lesson navigation, and private downloadable resources. It does not import course JSON or publish placeholder lesson content.

## Content compatibility

Each lesson has structured metadata and a JSONB `content` object. This is intentionally flexible so the agreed Claude JSON structure can be mapped after the first real course file is reviewed. The importer must validate and preserve the learner-visible explanation, step-by-step guide, key terms, practical exercise, and YouTube URL. It must split `lesson_quiz` into the protected assessment storage introduced in Step 8. Never place quiz answer keys or explanations in the learner-readable `content` JSONB field.

## Learner experience

- Authenticated learners can open published lessons.
- Learners can move to the previous and next published lessons, following module and lesson display order.
- Learners can mark a lesson complete. The server verifies the lesson ID belongs to the supplied course slug before saving progress.
- Resource metadata is shown on the lesson page. Downloads use signed URLs that expire after five minutes.

## Access boundaries

- Only authenticated users can read published modules, lessons, and resource metadata.
- A lesson is visible only when its lesson, parent module, and parent course are published.
- Learners can read and update only their own progress.
- Progress can only be created for a published lesson in a published module and course.
- Learners cannot delete progress records or write lesson content.
- Course content and resource records are writable only by the trusted service role.
- Downloadable files use a private Supabase Storage bucket. The storage SELECT policy checks that an object path is registered to a resource attached to a published lesson and course.
- The bucket is limited to 50 MB per object. Resource upload and administrative publishing workflows are not implemented in this step.

## Validation

Run `supabase test db` against a disposable local Supabase instance. The pgTAP suite checks table creation, RLS, grants, anonymous denial, learner progress isolation, published lesson visibility, private bucket configuration, and the storage download policy.

## Deferred

The exact Claude JSON importer, admin authoring interface, resource upload interface, assessment grading, progress dashboard, and course enrolment/subscription entitlements are separate implementation tasks. Before institutional paid access is introduced, course entitlement checks must be added to the relevant RLS policies.
