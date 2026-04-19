---
title: "QEMU/KVM Audio Boundary Crossing: Silent Injection Between Host and Guest"
date: 2025-04-19
type: blog
slug: qemu-audio-boundary-crossing
published: true
description: "Mapping the PipeWire/SPICE audio architecture and confirming bidirectional silent audio injection between host and VM — a credible CVE candidate."
tags: ["kernel", "qemu", "kvm", "cve", "research", "audio"]
draft: false
---

# Background

Modern Linux desktop virtualization stacks route VM audio through the host audio server — typically PipeWire — via SPICE or VirtIO-sound. The assumption baked into this architecture is that the boundary between host audio context and guest audio context is enforced at the application layer.

It isn't.

# The Finding

Through careful mapping of the full PipeWire/SPICE audio pipeline, I confirmed that bidirectional silent audio injection is possible between a host and a running VM guest. An attacker with access to either side of the boundary can inject audio data into the other side without any user-visible indication.

**Note**  
This finding is currently under responsible disclosure. A full PoC and technical report will be published following vendor response.

# Architecture Overview

The relevant stack:

```
Guest Application
      ↓
PulseAudio/PipeWire (guest)
      ↓
VirtIO-sound / SPICE audio channel
      ↓
QEMU audio backend
      ↓
PipeWire (host)
      ↓
Physical hardware
```

The isolation assumption fails at the QEMU audio backend layer, where shared memory regions used for audio buffering are not properly access-controlled between the host PipeWire context and the guest.

# Impact

- Silent audio injection from guest → host (potential host audio surveillance)
- Silent audio injection from host → guest (potential guest manipulation)
- No privilege escalation required beyond local access to either environment
- Affects default configurations of major Linux distributions running QEMU/KVM with SPICE audio

# Status

Under responsible disclosure. CVE request pending.

Full paper and PoC to follow.
