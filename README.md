# Origo Cloud Events — Reference Implementation

Business Central extensions showing how to add message types to
[Origo Cloud Events](https://github.com/OrigoSoftwareSolutions/bc-cloudevents), how to
retrofit an existing solution, and how to call one - from outside BC or from inside it. No
customer or internal implementation code anywhere in this repo - it exists purely to teach
the patterns.

## Start here

| Your situation | Read |
|---|---|
| **First time here** | [`QUICKSTART.md`](QUICKSTART.md) - clone, compile, call one message type, end to end |
| **Building a new message type from scratch** | [`EXTENDING.md`](EXTENDING.md) |
| **You already have an extension and want to add Cloud Events support** | [`ADAPTING.md`](ADAPTING.md) |
| **Calling Cloud Events from outside Business Central** | [`INTEGRATING.md`](INTEGRATING.md) |
| **Calling a message type from AL code already inside Business Central** | [`CALLING-FROM-AL.md`](CALLING-FROM-AL.md) |

## The three apps

| App | Shows |
|---|---|
| `Origo Cloud Events Reference` | Three message types built from nothing: no-fail, read + expected-error, write + isolation + unexpected-error. See `EXTENDING.md`. |
| `Legacy App` | Ordinary business logic with no awareness of Cloud Events - the "before" state for the retrofit example. |
| `Legacy App - Cloud Events` | Depends on `Legacy App` and Cloud Events Core, and wraps two of `Legacy App`'s procedures - one needs nothing but a thin wrapper, the other needed a precise refactor first. See `ADAPTING.md`. |

`Legacy App` and `Legacy App - Cloud Events` were added in separate commits on purpose -
`git log` on `Legacy App/src/LegacyStockMgt.Codeunit.al` shows the exact retrofit diff
`ADAPTING.md` describes, rather than asking you to trust the prose.

## Object ID ranges

All illustrative only - **never reuse these** for a real extension:

| App | Range |
|---|---|
| `Origo Cloud Events Reference` | `90000–90049` |
| `Legacy App` | `90050–90099` |
| `Legacy App - Cloud Events` | `90100–90149` |

Register your own: `50000–99999` for a per-tenant extension, or a range from Microsoft via
Partner Center for an AppSource app.

## Building it

CI (`.github/workflows/CICD.yaml`, `PullRequestHandler.yaml`) uses the standard
[Microsoft AL-Go for GitHub](https://github.com/microsoft/AL-Go) actions and compiles all
three projects on every push and PR. Because Cloud Events Core is a private repository, CI
needs a `GH_TOKEN_DEPS` secret (read access to `OrigoSoftwareSolutions/bc-cloudevents`)
configured on this repo - see `.AL-Go/settings.json`.

## Extension model

- `interface "Cloud Event Msg Interface ori"` — implement this; six methods, no `Access = Internal`.
- `enum "Cloud Event Message Type ori"` — `Extensible = true`; add your value via an enum extension.
- `table "CE Message Argument ori"` — the request/response carrier every implementation reads from and writes to.
- `codeunit "Cloud Events Dispatcher ori"` — the public, in-process entry point; see `CALLING-FROM-AL.md`.

This is the same pattern Origo's own dependent apps (Storage, Iceland, Arionbanki,
Landsbankinn, DocEx) use — nothing about the extension model is special-cased for Origo.

## What NOT to copy

If you've seen Origo's own Cloud Events extensions, copy the *pattern* shown here, not their
*content* — those call real external systems (banking APIs, government registries, document
exchange vendors) under commercial agreements that don't transfer to you. Everything in this
repo is deliberately synthetic, with zero external dependency.

