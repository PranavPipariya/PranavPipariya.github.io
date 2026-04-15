---
layout: post
title: "SP1 Is Mostly About Shape"
date: 2026-04-15 00:15:00 +0530
categories: zk notes
---

There is a way to talk about zkVMs that makes them sound supernatural.

You compile a normal Rust program, feed it some input, and out comes a proof that the computation happened correctly. That description is not wrong, but it hides the part that matters. The useful mental model is much more ordinary:

SP1 is a proving system for a very large, very disciplined table.

The table is not literally how you write the program. You still write Rust. But once the program is compiled down to RISC-V, what the prover is really dealing with is a trace of machine execution together with a bunch of side tables that explain the expensive parts. Once I started looking at it that way, SP1 stopped feeling like "Rust, but mysterious" and started feeling like a piece of systems engineering with a very sharp algebraic boundary.

## The Smallest Honest Story

Say the guest program reads two field elements \(a_0\) and \(a_1\), then iterates the Fibonacci recurrence

$$
a_{i+2} = a_{i+1} + a_i
$$

for \(n\) steps and commits to the final state.

At the level of execution, nothing exotic has happened. The machine just:

1. reads bytes from stdin,
2. decodes instructions,
3. mutates registers,
4. touches memory,
5. writes some public values.

The proving problem is to convince a verifier that every row of this execution is consistent with the previous row. If we call the machine state on step \(t\) by \(s_t\), the whole thing is just a transition relation

$$
s_{t+1} = F(s_t)
$$

applied over and over again, with extra constraints for memory consistency and special operations.

That is the real center of gravity. Not "prove arbitrary Rust" in the abstract. Prove that a huge sequence of tiny state transitions is internally coherent.

If you like thinking in costs, a useful cartoon is:

$$
\text{proof work} \approx
\text{CPU trace}
+ \text{memory argument}
+ \text{lookup / precompile tables}
+ \text{recursion overhead}
$$

That formula is not the protocol. It is just the right attitude.

## Why The RISC-V Boundary Matters

SP1 proves RISC-V execution, not Rust directly. This sounds like a minor implementation detail until you realize it is the entire interface contract.

Rust is for humans and compilers. RISC-V is for determinism.

Once the guest program is compiled into a RISC-V ELF, the prover no longer cares how elegant the original code was. It cares about the executed instruction stream, memory accesses, and any accelerated operations routed through precompiles. This is why zkVMs feel much more like architecture work than language work. The question is rarely "what does this function mean?" and much more often "what execution shape did this source code induce?"

That shift in perspective changes how you write programs for SP1. You stop obsessing over abstraction purity and start caring about witness shape:

- how many instructions did this induce,
- how much memory motion did it create,
- did I route expensive crypto through a precompile,
- can I keep the public output small and stable?

None of that is unique to SP1, but SP1 makes the tradeoff surface feel unusually concrete because the system is explicit about proving full machine execution rather than pretending the machine is not there.

## What The Host Actually Does

The host side is not complicated, which is one reason SP1 is compelling. The host prepares the ELF, writes the private input into stdin, runs setup, produces a proof, and optionally verifies it.

An illustrative Rust sketch looks like this:

```rust
use sp1_sdk::{include_elf, ProverClient, SP1Stdin};

pub const FIB_ELF: &[u8] = include_elf!("fibonacci-program");

fn main() -> anyhow::Result<()> {
    let client = ProverClient::from_env();
    let (pk, vk) = client.setup(FIB_ELF);

    let mut stdin = SP1Stdin::new();
    stdin.write(&8u32);
    stdin.write(&1u32);
    stdin.write(&1u32);

    let proof = client
        .prove(&pk, &stdin)
        .compressed()
        .run()?;

    client.verify(&proof, &vk)?;
    Ok(())
}
```

The important thing here is not the exact method names. Those can drift over time. The important thing is the shape:

1. setup binds you to a particular program,
2. stdin fixes the private witness,
3. proving commits to a concrete execution,
4. verification checks that the proof matches the verification key and public values.

There is a lot of machinery underneath that innocent-looking snippet. SP1 can split long executions into shards, recursively fold them, and then wrap the result into a proof that is easier to verify in the target environment. But the API still feels like "here is my program, here is my input, prove it," which is exactly the right product decision.

## The Part People Underestimate: Memory

Most of the intellectual weight in these systems does not sit in the arithmetic expression you wanted to compute. It sits in explaining why reads and writes line up across time.

If a machine reads address \(m\) at time \(t\), the verifier needs confidence that the value observed there is the one written by the most recent prior write to \(m\). That sounds banal, but it is the difference between proving a computation and proving theater.

The clean way to think about it is that execution produces two multisets:

$$
W = \{(m, t_w, v)\}
\qquad
R = \{(m, t_r, v)\}
$$

where writes and reads have to agree under the ordering discipline imposed by time. The proving system does not literally hand these to the verifier as giant explicit sets. Instead, it uses a memory argument that compresses the claim that the read/write story is globally consistent.

That is one reason performance conversations around zkVMs can get misleading. A "small" source-level function may still be expensive if it causes ugly memory behavior, while a "large" source-level function may prove surprisingly well if it mostly rides efficient execution paths and precompiles.

So when someone says a zkVM proves arbitrary Rust, what I hear is: it proves the machine story implied by that Rust, and the machine story is where the cost lives.

## Precompiles Are Not A Convenience Feature

SP1's README frames precompiles as an extension of the builtin idea: certain expensive operations can be discharged into dedicated tables rather than paying their full cost inside the generic CPU path. That is not a UX flourish. It is a structural bet about where generality should end.

You can imagine doing everything through a pure instruction trace. In principle that is wonderfully uniform. In practice it is a great way to turn common cryptographic operations into punishment.

What you want instead is:

$$
\text{generic CPU for control flow}
\quad + \quad
\text{specialized tables for recurring algebraic structure}
$$

The exact set of precompiles matters less than the architectural stance. A useful zkVM does not win by being philosophically pure. It wins by choosing the boundary where "general-purpose" stops being a virtue and starts being overhead.

This is one of the reasons SP1 feels like infrastructure rather than a research demo. It is trying to preserve the developer experience of normal Rust while being honest that some operations deserve dedicated proving paths.

## A Better Cost Model For Writing Guest Code

When I write normal systems code, I ask whether a change improves correctness, clarity, and runtime performance.

When I imagine writing serious SP1 guest code, I add two more questions:

1. What witness shape does this create?
2. Which part of the proving system am I forcing this through?

That immediately changes what "good code" means.

A tiny example. Suppose I want to expose some derived state as public output. The naive instinct is to write out everything that might be convenient later. But public values are part of the proof boundary. Making them larger than necessary increases coupling and can make downstream verification or application logic uglier than it needs to be.

The same thing happens with loops. A loop that is runtime-cheap in native execution may still be proving-expensive if it induces a large, repetitive trace without using any structure that the proving system can exploit efficiently.

The point is not "micro-optimize for the prover" from line one. The point is that once a program becomes something you want to prove repeatedly, you need a cost model that tracks algebraic shape, not just wall-clock time.

## The Verifier's Point Of View

I think zkVMs get much easier to reason about if you imagine being the verifier.

The verifier does not care that your Rust code was elegant. The verifier wants a short object asserting:

- this exact program was the one executed,
- this exact public output came out,
- there exists a valid private witness causing that execution trace,
- every row of the machine story checks out.

In other words, the verifier only sees the boundary:

$$
(\text{program commitment}, \text{public values}, \pi)
$$

and checks

$$
\mathsf{Verify}(\text{vk}, \text{public values}, \pi) = 1.
$$

That perspective is useful because it forces discipline. If a detail is not part of that boundary, it is an implementation concern. If it is part of that boundary, you should treat it as API design. This is especially true for programs intended to feed another protocol or an onchain verifier.

## Why SP1 Feels Like The Right Abstraction

The strongest thing about SP1 is not that it makes zero knowledge look magical. It is that it makes it feel like software.

You have a compiled artifact. You have stdin. You have public output. You have a proving mode. Underneath, the system is doing serious proof engineering: trace generation, lookup arguments, memory consistency, recursive composition, and final proof packaging. But the top-level abstraction remains narrow enough that a systems programmer can build a mental model without needing to become a proving-systems specialist on day one.

That is the line I keep coming back to: the good zkVMs are the ones that preserve the shape of ordinary software while being ruthlessly explicit about where the proof boundary actually is.

SP1, at least to me, reads like an attempt to make that boundary livable.

Not invisible. Not magical. Livable.
