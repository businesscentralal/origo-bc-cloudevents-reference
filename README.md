# Origo Cloud Events — Reference Implementation

A minimal, from-scratch Business Central extension showing how to add message types to
[Origo Cloud Events](https://github.com/OrigoSoftwareSolutions/bc-cloudevents). No customer
or internal implementation code — this exists purely to teach the pattern.

## Two things you can do with this repo

| You want to... | Read |
|---|---|
| **Build your own extension** to Cloud Events (add a new AL message type) | [`EXTENDING.md`](EXTENDING.md) |
| **Integrate** against Cloud Events from outside BC (another system, an MCP server, a host builder) | [`INTEGRATING.md`](INTEGRATING.md) |

## What's here

Three worked examples in `src/MessageTypes/`, each demonstrating a different part of the
contract:

| Message type | Codeunit | Demonstrates |
|---|---|---|
| `Reference.Echo.Set` | `RefEchoSetImpl` | The minimum viable message type — request in, response out, no failure path |
| `Reference.Table.Get` | `RefTableGetImpl` | A real read, with the structured `RespondWithError` failure path |
| `Reference.Note.Add` | `RefNoteAddImpl` + `RefNoteAddProcess` | A write, isolated in its own codeunit per the mandatory pattern, with `RespondWithLastError` |

Every codeunit implements `Cloud Event Msg Interface ori` (from Cloud Events Core) and is
registered against `Cloud Event Message Type ori` via `RefMsgType.EnumExt.al`. Every one also
writes its own help text via `GetMessageHelpAsMarkdownDocument` — so the examples are
runtime-queryable documentation, not just source you have to read.

## Object ID range

This repo uses `90000–90049` — **illustrative only**. If you're building a real extension,
register your own range (PTE: 50000–99999, or your own AppSource band). Never reuse Origo's
numbers; they mean nothing outside this repo.

## Building it

```bash
# Requires a compiled Cloud Events Core symbol package as a dependency (see app.json)
```

CI (`.github/workflows/CICD.yaml`, `PullRequestHandler.yaml`) uses the standard
[Microsoft AL-Go for GitHub](https://github.com/microsoft/AL-Go) actions to compile on every
push and PR. Because Cloud Events Core is a private repository, CI needs a `GH_TOKEN_DEPS`
secret (a token with read access to `OrigoSoftwareSolutions/bc-cloudevents`) configured on
this repo before builds will resolve the dependency — see `.AL-Go/settings.json`.

## Extension model

- `interface "Cloud Event Msg Interface ori"` — implement this; five methods, no `Access = Internal`.
- `enum "Cloud Event Message Type ori"` — `Extensible = true`; add your value via an enum extension, same as `RefMsgType.EnumExt.al` here.
- `table "CE Message Argument ori"` — the request/response carrier every implementation reads from and writes to.

This is the same pattern Origo's own dependent apps (Storage, Iceland, Arionbanki,
Landsbankinn, DocEx) use — nothing about the extension model is special-cased for Origo.

## What NOT to copy

If you've seen Origo's own Cloud Events extensions, copy the *pattern* shown here, not their
*content* — those call real external systems (banking APIs, government registries, document
exchange vendors) under commercial agreements that don't transfer to you. Everything in this
repo is deliberately synthetic, with zero external dependency.
