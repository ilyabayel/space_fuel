# Complete the three audit fixes from the partial implementation

## 1. Outcome, constraints, and implementation order

Implement all three confirmed findings:

1. **F1:** prevent ordinary edits from undoing a pending stage addition/removal.
2. **F2:** invalidate results when mass contains malformed text, including incomplete numbers.
3. **F3:** display every digit of large accepted results at mobile and desktop widths.

**Chosen interaction:** briefly block mission editing during structural form submissions. Do not queue edits or introduce a new synchronization protocol.

Resume the existing changes. The mass input is already text, wrapping styles and calculation fixtures have been added, and new browser regressions exist. Focused Elixir checks and the original browser tests were reported passing after an asset rebuild; final validation and visual inspection remain incomplete. Confirm current state from the working tree rather than treating these reports as fresh verification.

The first F1 approach failed: with a named submitter, the installed LiveView `putRef` skips `phx-disable-with` processing on other elements. Its internal DOM-update lock does not prevent a user changing a select. The current regression also attempts too many separate assertions inside a transient loading window. Both problems must be corrected.

Implementation order: **prove the corrected F1 lock and its deterministic test → complete F2/F3 coverage → inspect layouts → run final checks.** Preserve useful partial work. A bounded correction within this plan is authorized; an ordinary failed test is a reason to diagnose and continue, not to abandon the entire task.

Before editing:

- Read and apply the repository’s Elixir guidelines.
- Prefix shell commands with `rtk`.
- Inspect Git status and preserve existing changes.
- If the untracked `space_fuel_audit_20261030_d70g509b/` directory is present, leave it untouched and exclude it from commits. Preserve unrelated working-tree changes.
- Use the existing checkout. Do not create a worktree, add dependencies, publish, or deploy.

Primary implementation files:

- [Mission components](/Users/ilya/p/interviews/space_fuel/lib/space_fuel_web/components/mission_components.ex)
- [Application stylesheet](/Users/ilya/p/interviews/space_fuel/assets/css/app.css)
- The existing JavaScript entrypoint plus one new bundled `MissionFormLock` hook module.
- Existing domain, LiveView, and browser test modules.

**Keep the calculation services, formulas, gravity values, public context API, validation limits, and arbitrary-route semantics unchanged.** Use one small client hook to complete interaction locking; retain native form serialization and the existing server events. No new process, database, dependency, or mutation/revision protocol is needed.

## 2. Implementation changes

### F2 — Send every mass edit to server validation

Change the spacecraft mass input:

- Replace `type="number"` with `type="text"`.
- Add `inputmode="numeric"` to retain a numeric keyboard hint on mobile.
- Remove `min`, `max`, and `step`; they do not enforce numeric semantics on a text input.
- Keep the existing field binding, label, ID, class, and error presentation.
- Do not add `maxlength`: silently truncating an oversized paste could turn a rejected number into a different valid mass.
- Do not add client-side sanitization, numeric conversion, or character stripping.
- Do not add an HTML `pattern` or `required` constraint that prevents the existing LiveView validation flow.

The existing backend remains authoritative:

| Input | Required outcome |
|---|---|
| `28801` | Valid; Apollo produces `51,898 kg`. |
| `28801e`, `1e3`, `10.5`, `abc` | Invalid; show a validation error and remove the previous result. |
| Blank, `0`, negative integer | Invalid; existing validation messages apply. |
| `999999999999` | Accepted. |
| `1000000000000` | Rejected visibly; must not be truncated or converted. |

Preserve the existing distinction between ordinary changeset errors and raw-input boundary rejections. Both must make the result unavailable.

### F1 — Complete native submission handling with an explicit interaction lock

Keep the form’s existing:

```heex
phx-change="validate"
phx-submit="validate"
```

Ordinary typing and selection changes continue to recalculate through `phx-change`. Structural actions use `phx-submit`.

**Retain the already-started submit-button conversion:**

- Change both kinds of button from `type="button"` to `type="submit"`.
- Remove `phx-click={JS.dispatch("change")}`.
- Preserve their existing names and values:
  - Add: `name="mission[steps_sort][]"`, `value="new"`.
  - Remove: `name="mission[steps_drop][]"`, current row index as its value.
- Preserve all existing hidden sort/drop fields, UUID fields, button IDs, accessible labels, and the 50-stage disabled condition.
- Continue using the existing `validate` event handler. Do not introduce separate add/remove events.

LiveView serializes the named submitter into the submitted form. Its existing Ecto sort/drop handling therefore remains applicable.

**Complete interaction locking with a bundled hook:**

- Put `phx-hook="MissionFormLock"` and a stable `id="mission-planner"` on the existing planner wrapper enclosing the form, presets, Reset, and result panel.
- Add stable IDs to the preset-button group and pending-status element. The three lock targets are `#mission-form`, the preset-button group, and `#reset-mission`.
- Register the hook through the existing JavaScript entrypoint, preserving colocated hooks and all LiveSocket connection options.
- Remove the ineffective select `phx-disable-with` attributes. Retain `form="mission-form"` on preset and Reset buttons; native submission still manages their disabled state.
- The hook sets the native `inert` property on the three lock targets. `inert` blocks focus, keyboard, and pointer interaction without excluding fields from `FormData`. Let LiveView own `disabled`/`readonly` restoration.
- The hook manages transient attributes only. Keep the form and its children under LiveView rendering; do not apply `phx-update="ignore"` to the planner or form.

**Hook lifecycle and ownership:**

1. In `mounted`, register a capture-phase `submit` listener on the planner. Handle only submissions whose target is `#mission-form`. Register a `MutationObserver` on the planner for descendant class/child-list changes, so it observes native `.phx-submit-loading` transitions even when a reply changes no server assigns.
2. On the first connected form submission, synchronously enter pending state in the capture listener, before LiveView's window-level submit handler. Apply `inert` to all lock targets, then set `data-mission-pending="true"` and `aria-busy="true"` on the planner. Preserve submission propagation; LiveView must serialize the named submitter normally.
3. Track `pending` and `sawSubmitLoading` separately. A second submit while pending is prevented and stopped, so repeated activation cannot enqueue another structural operation. A microtask after the first event checks whether native `.phx-submit-loading` was entered. If submission never started, release the hook-owned lock rather than leaving the editor stuck.
4. Once `.phx-submit-loading` has been seen, release only when it is absent. The observer runs after the synchronous reply/DOM-update work; do not clear the lock merely because an arbitrary `updated` lifecycle callback ran. Ordinary pending `phx-change` replies must not release a structural lock early.
5. In `updated`, reapply the hook-owned attributes/inert state to current lock targets if still pending. Newly rendered rows must remain inside the inert form. The observer must query the current form rather than retain a stale form node.
6. Record elements that the hook changed from non-inert to inert. On release, clear inert only from those elements, remove pending/busy attributes, and reset local operation state. Never blanket-enable controls or overwrite server-rendered disabled states. In particular, Add stays disabled at 50 stages.
7. In `disconnected`, invalidate the current local operation and clear hook-owned locks. Reject structural form submissions while disconnected, but permit ordinary offline mass editing for existing form recovery. In `reconnected`, clear stale local state and resume normal submissions after LiveView recovery. Do not replay an uncertain add/remove automatically.
8. In `destroyed`, remove the capture listener, disconnect the observer, and clear owned attributes. Observer callbacks/microtasks must ignore a destroyed or superseded operation.

The hook observes browser DOM state and uses supported hook lifecycle callbacks. It must not access private LiveView view/channel objects, manually serialize the mission, create a second server request, or manipulate Phoenix's internal reference attributes. The implementation must prove ordinary reply, validation-error, and disconnect/reconnect restoration in browser tests before calling F1 complete.

**Preserve Enter-to-recalculate:**

Changing Remove buttons to submitters creates an HTML implicit-submission hazard: pressing Enter in the mass input could activate the first Remove button.

Add a neutral submit button as the **first submit button associated with the form**, before any stage controls:

```heex
<button
  id="recalculate-mission"
  type="submit"
  hidden
  aria-hidden="true"
  tabindex="-1"
>
  Recalculate
</button>
```

It must have:

- No `name`.
- No `value`.
- No `phx-click`.

Pressing Enter in mass must submit the current form without adding or removing any stage. Verify this with a real browser.

**Expose the hook's pending state:**

- Add a short status message, `Updating mission…`, with `role="status"`.
- Place the status outside the inert form and other lock targets so assistive technology can read it.
- Show it while the planner has `data-mission-pending="true"`.
- During that state, replace the visible `READY` indicator with `UPDATING`.
- Drive status CSS from the same pending attribute used by the hook. Remove obsolete rules that assume `.phx-submit-loading` alone means the entire editor is locked.
- Keep the last result readable while clearly marking it as updating.
- Style the pending editor without making control labels unreadable. Selects may remain `disabled === false` while their ancestor is inert; that is an effective interaction lock, not a failure.
- Do not lock the interface for ordinary `phx-change` typing.

**Completion and recovery behavior:**

- Successful and validation-error replies must both release the submission lock.
- The Add button must remain disabled when the acknowledged route contains 50 stages.
- Presets and Reset must work after the lock is released.
- Preserve LiveView’s built-in focus restoration and form recovery.
- Verify that a connection interruption during submission does not leave controls permanently read-only or disabled.
- No elapsed-time unlock or custom retry is needed. Native LiveView transport failure/recovery remains in charge of the connection; verify its integration with the hook rather than assuming that recovery passes.

### F3 — Wrap exact numbers instead of clipping them

Preserve exact integer formatting with comma separators. Do not use scientific notation, abbreviated units, ellipses, or floating-point conversion.

**Total-fuel markup and styling:**

- Give the numeric text its own span, such as `.total-value`.
- Give `kg` its own `.total-unit` span.
- Replace the existing broad `.total span` rule with `.total-unit`; otherwise the new numeric span would accidentally inherit the smaller unit font size.
- Keep the existing normal total font size.
- Allow the total container to wrap and grow vertically.
- Give the numeric span `min-width: 0`, `max-width: 100%`, and `overflow-wrap: anywhere`.
- Keep the unit readable and allow it onto a following line.
- Do not remove overflow protection globally from every panel.

**Stage breakdown:**

Replace the breakdown row’s unconstrained flex sizing with a grid:

- Desktop: index, fixed-size planet indicator, flexible stage description, flexible fuel amount.
- Use `minmax(0, 1fr)` for flexible columns.
- At widths of 600 px or less, place the fuel amount beneath the description, aligned with it.
- Give description and fuel containers `min-width: 0`.
- Allow long effective-mass and fuel values to wrap.
- Keep the planet indicator at its existing size and preserve flight order.

The result must remain readable at 320 px without creating page-wide horizontal scrolling.

## 3. Regression tests and acceptance criteria

Use the existing ExUnit, LiveViewTest, and PhoenixTest.Playwright dependencies. Do not introduce another browser-testing framework.

### A. Browser tests for the structural lock

First repair the pending-state observation. Keep the existing browser harness and add a small reusable browser-evaluation helper in the test module:

1. Resolve the form, named submit button, and current lock targets.
2. Call the native `form.requestSubmit(button)` and immediately return one plain-object snapshot in the **same JavaScript evaluation**. This dispatches normal form submission with the real submitter; it does not modify field values or bypass serialization. A network reply cannot run in the middle of that synchronous evaluation.
3. Snapshot the planner's pending/busy attributes; inert state of all lock targets; mass value and read-only state; select values and whether they have an inert ancestor; button disabled state; pending-status visibility; and route UUIDs/count. Explicitly check the hook-owned pending attribute, so a missing hook cannot produce a false pass.
4. Assert the returned snapshot in Elixir. Test all selects/controls, not merely the existence of one matching disabled select. Do not chain remote `assert_has` calls to reconstruct a pending state that may already have ended.
5. Then use retrying assertions to wait for pending/loading markers to clear and verify the acknowledged route, restored interaction, and exact total.

Use separate real keyboard/button tests for normal activation and Enter semantics. Supplementary latency tests may use `window.liveSocket.enableLatencySim(500)`, but delay duration is not the synchronization mechanism. If testing an attempted keyboard action during pending, record that pending was true when the action was attempted; an action performed after acknowledgement is not proof of blocking. Install any such browser recorder before activation and preserve its observations for later assertions. Do not weaken assertions merely to make a timing-sensitive test pass.

Disable simulated latency during cleanup or rely on destruction of the isolated browser context. Use no fixed sleeps.

**Add followed by attempted editing:**

1. Start with Apollo’s mass and remove all stages.
2. Enable latency simulation.
3. Submit Add and capture the atomic pending snapshot described above.
4. Assert from that snapshot:
   - The planner is pending and the form has `.phx-submit-loading`.
   - Form, presets, and Reset are inert.
   - The mass input is read-only.
   - Add is disabled.
   - Presets and Reset are disabled.
   - Updating status is visible.
5. Verify that the mass value in the snapshot is still `28801`; any supplemental blocked-input test must establish actual overlap as described above.
6. Wait for submission completion.
7. Assert exactly one Earth-launch stage exists.
8. Change mass to `1000`.
9. Assert exactly one stage and **517 kg**.

**Remove followed by attempted editing:**

1. Start with Apollo.
2. Enable latency simulation.
3. Submit removal of stage 2 and capture the atomic pending snapshot.
4. Assert the same pending lock. Every surviving select must be covered by an inert ancestor; do not require its own `disabled` attribute.
5. Verify original mass and current select values in the snapshot. Supplement with a real-user attempt under latency and retain evidence that it occurred while pending.
6. Wait for completion.
7. Change mass to `1000`.
8. Assert exactly these stages:
   - Launch Earth.
   - Launch Moon.
   - Land Earth.
9. Assert **1,155 kg**. The removed stage must not return.

**Important testing trap:** `fill_in` and select helpers may automatically wait until controls become editable. They cannot establish that an edit was blocked while pending. Use the atomic snapshot for deterministic lock assertions, normal keyboard tests for interaction semantics, and exact final route/totals for outcome assertions. Do not force `.value` changes and dispatch synthetic changes through inert/read-only controls; that bypasses the chosen user-interaction contract.

Also verify:

- Pressing Enter in mass preserves row count, UUIDs, actions, and planets.
- Repeated activation while pending does not create duplicate stages.
- Add/Remove still work with an ordinary invalid mass such as `0`; results remain unavailable and controls unlock.
- At 50 stages, Add remains disabled after completion.
- Removing one stage from the maximum route enables Add.
- Presets and Reset work after completion.
- Disconnect/reconnect during a pending operation restores an editable form without duplicate action replay.
- A validation reply that leaves server assigns unchanged still clears the hook's lock. Also cover a raw-input boundary rejection.
- An ordinary change response that arrives while a structural submission is pending does not unlock the editor early.
- Existing UUIDs and selected values survive the acknowledged middle deletion; the hook must not interfere with normal LiveView patches.

**F1 proof gate:** run the focused add/remove lock tests, Enter test, invalid-input unlock, and reconnect test against rebuilt assets before expanding other coverage. On failure, fix the local hook/test within the specified contract and rerun the affected test. Continue independent F2/F3 work if F1 needs further investigation. Escalate only when evidence shows that completing F1 requires changing the server event contract, adding a dependency, or expanding scope beyond this plan; report the exact sequence and remaining independent work rather than treating every regression as a global stop.

### B. Browser tests for malformed mass

Starting from Apollo’s valid result:

1. Type `28801e`.
2. Assert a mass error appears and the old fuel result disappears.
3. Blur the field and verify it remains invalid.
4. Correct it to `28801`.
5. Assert `51,898 kg` returns and the error clears.

Also cover blank, `0`, `-1`, `10.5`, `abc`, and an oversized paste.

Do not merely assert that the input value changed. Assert the result’s availability and error state.

### C. Large-result browser tests

Run at **320 × 900** and **1440 × 1000** viewports.

| Mission | Exact expected fuel |
|---|---:|
| Apollo route, mass `999999999999` | `1,849,866,067,144` |
| 50 Earth launches, mass `999999999999` | `336,681,682,585,413,579,314,401` |

Build the second route by clearing the form and adding 50 default Earth-launch stages. Wait for each structural submission to finish.

Assert:

- Exact numeric text.
- The full number remains available without abbreviation.
- Total container and breakdown rows do not overflow their allocated width.
- Document width does not exceed viewport width.
- Units remain visible.
- No unexpected browser console errors.

Take screenshots and inspect them. A matching DOM string alone does not prove that digits are visible.

### D. Small permanent calculation fixtures

Add these independently derived expectations to the existing tests:

- Maximum dry mass and 50 Earth launches:  
  `336_681_682_585_413_579_314_401`.
- Apollo with stage 2 changed to **Launch Mars**, mass `28_801`:  
  `61_668`.
- Apollo without stage 2, mass `1_000`:  
  `1_155`.

Strengthen the existing edited-stage LiveView test to assert **61,668**, replacing its weak “total differs from Apollo” check.

Keep all three official acceptance scenarios. Do not copy the entire audit oracle corpus into the repository.

## 4. Verification and completion

Run focused tests while implementing each fix. After all changes, execute:

```sh
rtk mix assets.build
rtk mix precommit
rtk proxy env E2E=1 mix test
rtk mix credo --strict
rtk mix dialyzer
rtk proxy mix sobelow --private --exit
```

Then verify production asset generation:

```sh
rtk proxy env MIX_ENV=prod mix assets.deploy
```

Operational notes:

- Inspect `mix precommit` before running it: it formats source and checks dependencies. Those mutations are appropriate during implementation, but inspect the resulting diff for unrelated changes.
- Browser tests require rebuilt assets; do not run them against an old JavaScript/CSS bundle.
- Use the existing browser installation. Install only declared project dependencies if genuinely missing.
- If the normal E2E port is occupied, use the documented `E2E_PORT` override.
- The audit found an existing Sobelow CSP warning. Report it accurately; do not claim the scan is clean, suppress it broadly, or redesign CSP as part of these fixes.

Update README briefly to explain:

- Positive whole-kilogram validation remains server-side.
- Add/Remove briefly block editing until the update completes.
- Large totals remain exact and may wrap.

**Definition of done:**

- All existing tests and new regressions pass.
- Deterministic browser snapshots prove that the pending-operation lock covers mass, every select, Add/Remove, presets, and Reset; final assertions prove it releases correctly.
- Enter never deletes or adds a stage.
- Malformed mass never leaves the previous result marked READY after validation completes.
- Every digit of supported large totals is readable at both tested widths.
- Reconnection does not leave the editor locked.
- Calculation behavior and resource limits remain unchanged.
- The final diff contains only intended source, test, and documentation changes.
- The untracked audit-copy directory is excluded.
- The completion report lists changes, executed checks, failures, and remaining limitations.

## 5. Scope boundaries and handoff defaults

- This plan authorizes implementation of the three fixes and their tests, not an architectural refactor.
- Keep the existing public APIs, result type, form field names, event names, and Ecto sort/drop contract.
- Native form submission changes only how structural actions reach the existing handler.
- The new hook completes user-interaction locking around native submission. LiveView retains serialization, server communication, DOM rendering, and native control restoration. A small hook is explicitly within scope.
- GitHub publication/access remains a separate delivery check. Report whether a remote and reviewable URL exist; do not create, push, or publish a repository without a separate request.
- Preserve the partial implementation and finish all independently verifiable work. Use the F1 proof gate above for local iteration and the precise escalation boundary; do not repeat the superseded assumption that `phx-disable-with` disables non-submitter selects.
