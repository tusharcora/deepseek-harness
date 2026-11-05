# Crew plugins: plan

Status: draft, waiting for approval. Nothing is built yet.

## Shared conventions

- Every plugin is a package at `packages/experimental/crew-<name>`, named `@deepseek-ai/dsh-experimental-crew-<name>` (the experimental naming policy requires the prefix), version-aligned with its neighbours. Each has a `README.md` in the repo's section layout, `locale/en.json`, `src/`, `tests/`, and `"license": "MIT"`. A plugin with config rows ships `cordis.patch.yml` with `icon.svg` and declares `dsh.bundle`, as `personalized-recommendations` does, so `plugin_manager` installs it on its own.
- Client UI copy comes from typed `locales.ts` dictionaries and goes through `ctx.locale` and `t`. CSS modules use only `--dsw-alias-*` and the radius tokens. Primary buttons use `Button` from `dsh-client-ui-primitives`, which follows brand-primary. DeepSeek blue appears only as an accent.
- Tests: `*.spec.ts` on the Host and `*.client.spec.tsx` in the browser, in the style of each pattern package.
- After each plugin: run its tests, `pnpm run build:artifacts`, install with `plugin_manager`, check it at http://127.0.0.1:3080, then report what works and what doesn't.
- Work goes on a branch. Nothing is committed until you say so.
- Nothing sends, posts, buys, deletes, merges or books without a click. Every such action is an `ctx.actionCards` kind whose handler runs only from the Remote `act()` that the user's click triggers, and the model never gets a tool that performs the action directly.
- Credentials go only through `ctx.credentials` references and `ctx.authorization` flows. No file holds a secret.
- Every price, score or date shows its `source` and `fetchedAt`. Fixture data in UI is labelled "Sample data".

## 1. crew-faces

- Seam: none, because it's a client library. It exports `CrewFace({ agentId, mood: 'idle'|'working'|'needs-you', size, label })` and a pure `faceGeometry(agentId, mood)`.
- Geometry follows the spec exactly: four bodies, the face circle per body, and two pill eyes with `rx = w/2` at the given offsets and rotations. In the "working" mood both eyes shift up and right.
- Body and colour come from a stable hash of the agent id. Eyes are `#17181A`, or white when the body is `#0B0B0C`. There's no background shape. The blink is a CSS `scaleY` keyframe every few seconds, offset per id, and it's turned off under `prefers-reduced-motion`. The SVG has `role="img"` and an `aria-label`.
- Tests: the exact centre, width, height and rotation of both eyes for each body; the same id always gives the same face; the eye-colour rule; the working shift; the aria label; reduced motion.

## 2. crew-agents

- Seams:
  - Six `dsh-agent-preset` rows in `cordis.patch.yml`: `crew-mail`, `crew-chat`, `crew-code`, `crew-research`, `crew-life` and `crew-chief`. Each has a `dsh-persona` and its own tool rows.
  - The Chief of staff mounts `dsh-tool-subagent` with `provider: spawn` and `allowedAgentPresets: [crew-*]`, plus `dsh-agent-team` and `dsh-tool-agent-team`.
  - A Host service, `ctx.crew`, with an `@Remote` roster stream giving each agent's id, preset, name and status. Its client half shares that observable with the other crew plugins.
- Status:
  - **working**: a turn is open, read from `turnBoundaryOf`.
  - **needs you**: the Session has an unstarted action card or an unanswered `userQuestions` entry.
  - **idle**: anything else.
- Tools until accounts are connected:
  - Mail: web and read-only fs.
  - Chat: web.
  - Code: bash, fs, lsp and forge.
  - Research: web.
  - Life: schedule and web.

  The Gmail, Slack and Telegram tools wait for the "real accounts" step.
- Tests: all six presets load and validate; chief delegation refuses a preset outside the allowlist; status derivation covers working, needs-you and idle; the roster Remote is checked for access.

## 3. crew-stock-chart

- Seams:
  - The `ui_stock_chart({symbol, range})` tool on `ctx.tools`. Its result metadata carries `{symbol, range, series[], source, fetchedAt}`.
  - An `@Remote` `quote(symbol, range)` that the card uses for range switching and refresh, so neither needs the model.
  - A `tool.call.toolview` row keyed `ui_stock_chart`.
  - A `conversation.chat.turnTail` card in the style of ui-schedule.
- Card: price, change, 1D/5D/1M/6M/1Y buttons, a line/candles toggle and a hover crosshair readout, all drawn as SVG with no new dependency. Refresh interval and provider are config fields. On a failed refresh the card keeps the last good series and shows "as of <fetchedAt>".
- Tests: provider parsing; the tool result's fields; range and toggle make no model call; the crosshair readout; a failed refresh keeps the old data and its time; the toolview phases.

## 4. crew-desktop

- Seams: `ctx.sidebarRightTabs.register({ kind: 'crew-desktop' })`, plus `sidebar.right.pane.tab` and `.title` seats. This is the same path that ui-sidebar-terminal and ui-sidebar-browser use.
- v1 frames: the latest screenshot image from the Session's computer-use tool results, loaded through the Gateway `loadImage`. `ctx.computerUse` has no common screenshot API, so this updates once per agent action and is not a continuous stream.
- Controls:
  - **Pause** interrupts the agent's current turn through the Session controller.
  - **Take over** pauses, then shows a "you're in control" state until you resume.
  - The where-it-runs label comes from the registered provider name and the host.
- noVNC comes later.
- Tests: frame selection; empty, paused and taken-over states; button labels and aria; Pause calls interrupt.

## 5. crew-today

- Seams:
  - A `main` page and a `sidebar.panellist` entry, registered as in ui-schedule.
  - A Host `ctx.crewToday` Remote with these parts:
    - Crew chips come from `ctx.crew`.
    - The digest comes from crew-digest's store.
    - The approvals are the unstarted crew action cards across crew Sessions, read from the `actionCards` projection.
    - The PRs come from `ctx.forge` through forge-github.
    - The calendar comes from the account connector.
- Approval cards: Send or Merge and Edit call the same `remote.actionCards.act()` that the transcript card uses. Edit opens a form whose edited fields go in the act payload.
- The week's calendar shows a "Connect calendar" empty state until an account is connected. It never shows invented events.
- The stock card reuses crew-stock-chart's component.
- Tests: each section's loading, empty and error states; approvals act through the Remote only; PR rows show their source and time; the sidebar entry's label and aria.

## 6. crew-digest

- Seams:
  - On load, an effect makes sure one `ctx.schedule` task exists: daily at 08:00 in the configured time zone, destination a new Session with preset `crew-mail`. It looks the task up by a stable name and never creates a duplicate.
  - A `crew_digest_write` tool lets the Mail agent store the digest with its sources and time in `ctx.storageDomain`. Today reads it from there.
- Tests: task creation is idempotent across reloads; the rule and time zone; write then read; Today sees the newest digest.

## Stop-and-ask points (from the brief)

Core change A (`sidebar.sections`), core change B (webhook continuing a session), connecting real accounts, and the Vercel Sandbox providers.

## Open questions before step 1

1. **Face palette.** Which body colours should the hash pick from? My proposal is six tokens: `#0B0B0C`, DeepSeek blue, and four muted hues that read well on both themes.
2. **Model per agent.** One `subagent` tool with `allowedAgentPresets` can't give each child its own model. Option A keeps one tool, and children use the default or a model the chief chooses. Option B uses five tool instances (`ask_mail`, …), each with `agentPreset` and `agentOptions.model`. I recommend B, unless a preset can carry its own model selection. I'll check that in agent-preset-registry first.
3. **Stock data source.**
   - Stooq: free, no key, daily bars only, so no intraday 1D.
   - Yahoo chart endpoint: intraday, no key, unofficial.
   - A keyed API through `ctx.credentials`: Alpha Vantage, Finnhub or Polygon.
4. **One card per turn.** action-cards allows one card per turn, and a newer card replaces an unstarted older one in the same Session. For several pending approvals, either each approval gets its own crew Session, or I extend `action-cards`. Extending it is an experimental package, but still an edit outside crew-*.
5. **Licence headers.** The repo has no per-file headers; it uses `"license": "MIT"` and the root LICENSE. Should I add SPDX headers anyway?
6. **Docs gates.** `docs/` is covered by doc-sync and bilingual pairing. If this file trips them, I'll move it to `.agents/notes/` unless you'd rather keep it here.
