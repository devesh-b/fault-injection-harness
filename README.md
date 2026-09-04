# fault-injection-harness

A bit-flip **saboteur** primitive for hardware fault-injection campaigns, and a
testbench that uses it to demonstrate exactly where triple-modular redundancy
protects you and where it does not.

The idea is simple and reusable: give every redundant copy of a register its own
`inject` port that XORs into the stored value. A testbench can then flip any bit
of any copy on any cycle, and the design under test needs no special build — the
injection is part of the module's interface, not a simulator hack.

## What it shows

`tb_tmr.v` drives a 3-copy voted register through five cases and checks the
voted output each time:

| Injected | Voted output | Verdict |
|---|---|---|
| nothing | correct | baseline |
| 1 bit in copy 0 | correct | **masked** — redundancy did its job |
| 1 bit each in copies 0 and 1, *different* positions | correct | **masked** — the votes still disagree per bit |
| 1 bit each in copies 0 and 1, **same** position | **wrong** | **TMR defeated** |
| nothing | correct | recovers on the next cycle |

The fourth row is the point. Bitwise majority voting protects against faults
that land in different bit positions, and two copies agreeing on a *wrong* bit
outvote the one correct copy. A `fault_seen` flag reports voter disagreement,
so detection and correction can be scored separately — a distinction that
matters, because a wrong answer nobody flagged is a different failure from a
wrong answer that was caught.

## Run it

Needs [Verilator](https://verilator.org) 5.05+ on `PATH`. No other dependencies.

```bash
verilator --binary --timing rtl/tmr_reg.v tb/tb_tmr.v --top-module tb_tmr -o sim_tmr
./obj_dir/sim_tmr
```

Expected tail: `TMR saboteur smoke test PASSED`.

## Layout

| Path | What |
|---|---|
| `rtl/tmr_reg.v` | TMR register, parameterised width, per-copy saboteur port |
| `tb/tb_tmr.v` | self-checking testbench, the five cases above |

## Scope

This is the injection primitive and its proof of behaviour, not a campaign
framework. There is no fault-rate model, no random campaign driver, and no
coverage accounting — those belong to whatever design is being hardened. What
is here is the piece that has to be right before any of that is worth running.

## Licence

MIT.
