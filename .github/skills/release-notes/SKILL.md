# Release Notes Skill

Use this skill whenever preparing a new application release.

## Purpose

Create clear, concise, user-facing release notes for `RELEASE_NOTES.md`.

The release notes will be used as the GitHub Release body and displayed in the app under **What's New**.

## Requirements

* Keep each release note to one line when possible.
* Focus only on changes users will notice.
* Use action-oriented wording.
* Include approximately 3–8 items per release.
* Use a bullet character at the start of each item.
* End each item with a period.
* Keep the language simple and concise.
* Update `RELEASE_NOTES.md` before creating the release tag.

## Allowed Prefixes

Use one of these prefixes for every item:

* `Added` — new functionality
* `Improved` — usability, performance, or behavior improvements
* `Fixed` — bug fixes
* `Updated` — changes to existing functionality
* `Removed` — removed features or behavior

## Format

```text
• Added ...
• Improved ...
• Fixed ...
```

## Example

```text
• Added auto-scroll to the first required field during validation.
• Added a warning before discarding unsaved changes.
• Improved the installation flow after enabling unknown sources.
• Fixed customer deletion after all debts were paid.
```

## Avoid

Do not include:

* Class names
* Function names
* File paths
* Package names
* Commit hashes
* Pull request numbers
* Issue numbers
* Database migration details
* Internal implementation details
* Developer-only terminology
* Changes that users cannot observe

Bad example:

```text
• Updated UpdateProviderNotifier in update_providers.dart.
• Fixed issue #42 using package_info_plus.
• Refactored the APK installation service.
```

Better example:

```text
• Improved update detection reliability.
• Fixed APK installation after enabling unknown sources.
• Improved the update download experience.
```

## Release Workflow

When preparing a release:

1. Review all changes since the previous release.
2. Identify only user-visible changes.
3. Categorize each change as Added, Improved, Fixed, Updated, or Removed.
4. Write 3–8 concise release-note items.
5. Replace the contents of `RELEASE_NOTES.md`.
6. Verify that the notes match the version being released.
7. Commit the updated release notes with the version change.
8. Create and push the release tag only after the notes are ready.

Do not generate release notes from commit messages without rewriting them into clear, user-facing language.
