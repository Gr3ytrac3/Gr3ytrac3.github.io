---
title: My New 2026 - 2028 Roadmap
---

Found a sort of dream [security_researcher_linux_kernel](https://opensrcsec.com/security_researcher_linux_kernel) job at Open Source Security and to be honest, it describes the perfect environment I'm very certain to not only contribute but reach my ultimate goal as well, which is to become to excellently good at what I do and be among them that keep the cyber industry secured. 

But right before this , i must be honest with myself. I'm far from having the full confidence to shoot my shot for this position because I truly haven't gotten a track that's truly amazing and matches their ideal security researcher. Yes I am so invested into my field and i think that's all that matters now, both for them and me. After giving it a thought, I decided to make it my next roadmap goal to certainly achieve and apply to that post.

As for the time frame, to be honest, i have no idea. What this roadmap sugests is a decent time, considering all that i need to take in, from knowledge to experience and works (of course verifiable). Nothing as well is stopping from completing it before the two years, but one thing I'm sure of, I'm not relenting, nor wasting time. This position will certainly have me in it and I'm ready to pay the price of consistency in order to get there. 

Anyways, let's not talk to much and get on with the roadmap 

---

# The OSS/grsecurity Path — 24 Month Natural Progression

The philosophy here is **depth over breadth, one season at a time.** Each phase has a natural theme. You don't rush to the next one until the current one feels internalized, not just completed.

---

## Phase 1 — Solidify the Foundation (Months 1–4)

**Theme: become dangerous with what you already know.**

The goal here isn't learning new things — it's sharpening and publishing what you've already built. You have real research sitting unpublished. That changes now.

**Kernel exploit depth**
- Work through pawnyable.cafe completely if you haven't. Every technique, every exercise.
- Pick 2–3 recent public kernel CVEs (from the last 12 months) and reproduce the exploits from scratch — not from a PoC, from the patch diff alone. Document your process.
- Get comfortable with ret2usr, SMEP/SMAP bypasses, heap spray techniques, and KASLR defeat as a baseline.

**Publishing cadence — start small, stay consistent**
- Publish your QEMU/KVM audio boundary finding properly. Get the CVE assigned. Write the blog post on The OffSec Desk or Substack. This is already done research — it just needs to ship.
- Write up one of the CVE reproductions you did above as a technical blog post. Detailed, first-principles, your voice.
- Target: one published piece per 6–7 weeks. Not more. Quality over frequency.

**C mastery**
- You know C. Now go deeper. Read the C standard sections on undefined behavior, aliasing, and memory model. This matters for kernel work specifically.
- Read through kernel source for one subsystem you care about (scheduler, memory management, or the VFS). Not to exploit it yet — just to read it fluently.

---

## Phase 2 — New Territory: Microarchitecture (Months 5–9)

**Theme: learn the hardware layer.**

This is the biggest gap and the most intellectually rich. Don't treat it as a checkbox — treat it as a genuinely fascinating subject, because it is.

**Start with understanding, not exploitation**
- Read the original Spectre and Meltdown papers end to end. Then read the academic responses — retpoline, IBRS, STIBP. Understand *why* each mitigation works at the hardware level.
- Read "A Systematic Evaluation of Transient Execution Attacks and Defenses" (Canella et al., 2019). It maps the entire space.
- Set up a test environment (your ASUS + QEMU) and run the existing Spectre PoC code. Instrument it. Measure cache timing yourself with `rdtsc`. Make it tangible.

**Go deeper**
- Study Flush+Reload, Prime+Probe, and EVICT+RELOAD as primitives. Implement a basic cache timing side channel from scratch in C — just measuring, not exploiting yet.
- Read the MDS (Microarchitectural Data Sampling) papers — TAA, RIDL, Fallout. These are closer to what OSS cares about.
- Study how grsecurity's kernel mitigations interact with these attack classes. Their blog posts are public and technically dense — treat them as required reading.

**Research output from this phase**
- By month 9, you should be able to write one solid technical piece on a specific microarchitectural primitive — your own implementation, your own measurements, your own analysis. Not a survey. An experiment.

---

## Phase 3 — ARM64 and Multi-Arch Thinking (Months 10–14)

**Theme: stop thinking x86-only.**

You don't need to master PowerPC. You need to understand ARM64 deeply enough to reason about exploitation differences, and show that you can.

**ARM64 internals**
- Get an ARM64 environment running — a Raspberry Pi, or QEMU emulating aarch64. Boot a kernel, attach a debugger, feel the architecture.
- Read the ARM Architecture Reference Manual sections on memory model, exception levels (EL0–EL3), and the MMU. These map directly to exploitation primitives.
- Port one of your existing x86 kernel exploits or PoCs to ARM64. The process of porting teaches you where the architecture assumptions were buried in your original code.

**Comparative analysis as research**
- The most natural research output here is a comparative piece: "here's how this exploitation technique differs between x86\_64 and AArch64, and why." That kind of writing demonstrates multi-arch thinking without requiring you to be an ARM expert.

---

## Phase 4 — Speculation + Kernel Exploitation Synthesis (Months 15–19)

**Theme: combine everything into original research.**

By now you have: kernel exploit depth, microarchitectural understanding, multi-arch awareness, and a publishing track record. This phase is where those threads combine.

**Target: one original research project**
- Pick an attack surface at the intersection of what you know. Examples: a speculative execution primitive in a specific kernel subsystem, a side channel in a virtualization boundary (you already have QEMU context), or a cross-privilege information leak.
- This doesn't have to be a zero-day. It can be a novel *technique* applied to a known class of vulnerability, or a measurement study of how a specific mitigation performs under adversarial conditions.
- The deliverable: a technical writeup long enough to submit to a conference, or to post as a serious research artifact.

**Conference submissions**
- Linux Security Summit (LSS) — abstract submissions open ~4 months before the event, usually around March for the EU edition and May for NA. They accept research talks and are the most directly relevant venue.
- Submit something here. Even a 20-minute talk proposal. The act of writing a proposal forces clarity.
- Smaller venues first if needed: BSides events, FOSDEM kernel track, virtual events. Speaking once anywhere breaks the "no conference experience" gap.

---

## Phase 5 — Application Readiness (Months 20–24)

**Theme: consolidate your identity as a researcher.**

By this point you're not "becoming" — you're already doing the work. This phase is about making that visible and coherent.

- Audit everything you've published. Is it findable? Is it good? Does it tell a coherent story about who you are as a researcher?
- Make sure your GitHub, blog, and public profiles reflect the last two years of output — not just the early stuff.
- If the CVE is assigned and published, it goes front and center everywhere.
- Write a serious piece on grsecurity's attack surface specifically — study their public patches, understand what they protect against, and write about it. This signals to OSS that you've done your homework on *them*, not just kernel security generally.
- Then apply. With that body of work, your application writes itself.

---

## The Guardrails — How Not to Break Yourself

A few things to hold onto over the two years:

**One deep thing at a time.** The phases exist so you're not trying to learn microarchitecture and ARM64 simultaneously. Context-switching between deep subjects at this level is expensive. Resist it.

**Publish before it's perfect.** Every piece you sit on because it "needs more work" is a piece that never helps you. Rough and real beats polished and unpublished.

**Rest is not waste.** At 30+ hours a week of this kind of work, your brain needs unstructured time. The ideas often arrive there.

**The application is not the goal.** OSS is a useful north star, but the actual goal is to become someone who does this work seriously. If you do that, the application is just paperwork.