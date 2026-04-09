# TODO - PulseFeeNTick-hook

This file lists the next implementation steps for Claude Code.
It is intentionally structured from architecture first, then storage/math, then contract flows, then testing.

---

## Phase 0 - repository and scaffolding

- [ ] Initialize project structure for a Uniswap v4 hook repository
- [ ] Decide and set toolchain:
  - [ ] Foundry
  - [ ] v4-core dependency
  - [ ] v4-periphery dependency if needed
- [ ] Create base folders:
  - [ ] `src/`
  - [ ] `test/`
  - [ ] `script/`
  - [ ] `docs/`
- [ ] Add `.env.example` if deployment scripts are planned
- [ ] Add formatting and linting config

---

## Phase 1 - write the technical spec before coding deeply

- [ ] Write `SPEC.md` that formalizes all agreed behavior
- [ ] In `SPEC.md`, define:
  - [ ] hook responsibilities
  - [ ] vault responsibilities
  - [ ] keeper responsibilities
  - [ ] protocol fee accounting responsibilities
- [ ] Define all storage variables before implementation
- [ ] Define event list
- [ ] Define custom errors
- [ ] Define trust assumptions
- [ ] Explicitly describe internal rebalance swap flow
- [ ] Explicitly describe how internal swaps are identified so fee exemption is possible

---

## Phase 2 - core architecture decisions to lock down

- [ ] Finalize contract split
  - [ ] single monolithic hook vs helper contracts
  - [ ] whether to use a separate `RebalanceManager`
- [ ] Decide exact receipt model
  - [ ] NFT-style receipt with share accounting underneath
  - [ ] exact token standard and metadata strategy
- [ ] Decide whether protocol fee treasury is internal to hook or external module
- [ ] Decide how keeper rewards are claimed and accounted

---

## Phase 3 - storage and math design

### 3.1 Fee state
- [ ] Implement storage design for:
  - [ ] `cachedFee`
  - [ ] `lastFeeUpdateTimestamp`
  - [ ] `minFee`
  - [ ] `maxFee`
  - [ ] `C`
- [ ] Implement fee refresh function callable by keeper
- [ ] Decide whether `beforeSwap` can ever fallback-refresh if cache is stale

### 3.2 Decayed volume state
- [ ] Design storage for global decayed volume `L`
- [ ] Design storage for per-usable-tick decayed volume `L_tick`
- [ ] Store timestamps needed for lazy hourly decay
- [ ] Implement lazy decay math for elapsed whole hours
- [ ] Decide fixed-point precision for `0.8^n`
- [ ] Handle very old stale states safely

### 3.3 Tick accounting
- [ ] Implement usable tick normalization helpers
- [ ] Implement local sum calculation:
  - [ ] `center * 2`
  - [ ] `±1`
  - [ ] `±2`
- [ ] Ensure only usable ticks are used everywhere

### 3.4 Base token accounting
- [ ] Define how deployment specifies the base token
- [ ] Implement helper to measure user swap volume in that base token
- [ ] Ensure internal rebalance swaps bypass this accounting

---

## Phase 4 - hook swap flow

### 4.1 beforeSwap
- [ ] Implement dynamic LP fee override path
- [ ] Return pool-wide fee using cached fee logic
- [ ] Charge extra `1bp` hook fee for external user swaps
- [ ] Exempt internal rebalance swaps from extra `1bp`
- [ ] Exempt internal rebalance swaps from dynamic LP fee if architecture allows
- [ ] Add clear branch for identifying internal swap caller/context

### 4.2 afterSwap
- [ ] Update volume accounting only for external swaps
- [ ] Update `L`
- [ ] Update relevant `L_tick`
- [ ] Determine final usable tick space after swap
- [ ] If vault active range is stale, set `needsRebalance = true`
- [ ] Emit event for stale vault / rebalance needed

---

## Phase 5 - shared 1-tick vault

### 5.1 Vault accounting
- [ ] Implement shared-vault share accounting
- [ ] Implement vault NAV calculation
- [ ] Track idle assets and active position assets
- [ ] Decide how to account for dust

### 5.2 Deposit
- [ ] Implement deposit entrypoint for vault LP users
- [ ] Require rebalance first if `needsRebalance == true`
- [ ] If rebalance fails, deposit reverts
- [ ] Convert deposit toward optimal range ratio
- [ ] Mint vault receipt/shares
- [ ] Emit deposit event

### 5.3 Withdraw
- [ ] Implement withdraw entrypoint for vault LP users
- [ ] Attempt rebalance first
- [ ] If rebalance succeeds, withdraw from current proper state
- [ ] If rebalance fails, still allow lenient withdrawal from current vault state
- [ ] Burn vault receipt/shares
- [ ] Emit withdrawal event

---

## Phase 6 - rebalance flow

### 6.1 Rebalance interface
- [ ] Implement public `rebalance()` entrypoint
- [ ] Make `needsRebalance` publicly readable
- [ ] Emit events before and after rebalance

### 6.2 Rebalance mechanics
- [ ] Remove stale active liquidity
- [ ] Compute current vault inventory after removal
- [ ] Determine target current usable tick space
- [ ] Compute desired ratio for target 1-tick range
- [ ] Perform internal balancing swap in same pool if needed
- [ ] Re-add liquidity to `[tickLower, tickLower + tickSpacing]`
- [ ] Clear `needsRebalance` on success

### 6.3 Rebalance failure handling
- [ ] Decide which failures revert fully
- [ ] Decide how to surface partial-failure diagnostics
- [ ] Ensure failed rebalance does not corrupt share accounting

---

## Phase 7 - keeper incentives

### 7.1 Incentive source
- [ ] Implement protocol revenue bucket funded by external swap `1bp`
- [ ] Track keeper incentive budget

### 7.2 Rebalance keeper rewards
- [ ] Implement reward distribution for successful `rebalance()` callers
- [ ] Decide reward formula:
  - [ ] fixed reward
  - [ ] time-based reward
  - [ ] work-based reward
- [ ] Prevent reward overpayment relative to treasury

### 7.3 Fee refresh keeper rewards
- [ ] Implement `pokeFee()` / `refreshFee()` keeper entrypoint
- [ ] Reward keeper for refreshing cached fee if this path is adopted
- [ ] Prevent spam refreshes
- [ ] Add freshness interval guard

---

## Phase 8 - coexistence with normal Uniswap liquidity

- [ ] Ensure standard LPs can still add/remove liquidity normally
- [ ] Ensure vault logic does not break standard LP path
- [ ] Confirm pool-wide dynamic fee applies to all swaps uniformly
- [ ] Confirm vault-specific accounting only affects vault participants

---

## Phase 9 - admin and safety controls

- [ ] Implement pause functionality
- [ ] Decide which functions are pausable:
  - [ ] swaps?
  - [ ] deposits?
  - [ ] withdrawals?
  - [ ] rebalance?
- [ ] Ensure pause behavior is consistent with lenient withdrawals
- [ ] Add emergency event logging

---

## Phase 10 - testing plan

### 10.1 Unit tests
- [ ] Test usable tick normalization
- [ ] Test local sum calculation
- [ ] Test hourly decay math
- [ ] Test fee clamp behavior
- [ ] Test internal swap exclusion from volume tracking
- [ ] Test internal swap exemption from 1bp fee
- [ ] Test stale vault detection

### 10.2 Integration tests
- [ ] Test normal user swap with dynamic fee
- [ ] Test repeated swaps changing `L` and `L_tick`
- [ ] Test crossing into a new tick space and marking `needsRebalance`
- [ ] Test successful public `rebalance()`
- [ ] Test deposit strictness when stale
- [ ] Test withdraw leniency when rebalance fails
- [ ] Test coexistence with normal Uniswap LP

### 10.3 Economic tests
- [ ] Simulate concentrated local activity lowering fee
- [ ] Simulate sparse local activity raising fee
- [ ] Simulate large jump across many ticks
- [ ] Simulate repeated keeper rebalances
- [ ] Simulate protocol fee treasury depletion
- [ ] Simulate manipulative fee-lowering flow

### 10.4 Fuzz tests
- [ ] Fuzz fee update logic
- [ ] Fuzz rebalance accounting
- [ ] Fuzz share mint/burn correctness
- [ ] Fuzz stale/active range transitions

---

## Phase 11 - open implementation questions Claude Code should resolve carefully

- [ ] Best exact method to distinguish internal rebalance swap from external user swap in v4 hook flow
- [ ] Whether zero-fee override for internal rebalance swap is fully compatible with final hook architecture
- [ ] Best token standard for vault receipt while preserving NFT-like UX
- [ ] Exact optimal-ratio deposit path for a 1-tick usable range
- [ ] Best keeper reward formula for fee refresh and rebalance
- [ ] Gas-efficient storage design for sparse per-tick decayed volume map

---

## Phase 12 - documentation

- [ ] Expand README with architecture diagram
- [ ] Write SPEC.md
- [ ] Write DEPLOYMENT.md
- [ ] Write TESTPLAN.md
- [ ] Write SECURITY-NOTES.md

---

## Implementation priority recommendation

Recommended coding order:

1. Write SPEC.md
2. Implement math helpers and storage layout
3. Implement fee refresh and volume accounting
4. Implement basic swap hook path
5. Implement shared vault accounting
6. Implement rebalance flow
7. Implement keeper incentives
8. Add NFT/share receipt layer
9. Add full test suite
10. Revisit optimization and gas reduction
