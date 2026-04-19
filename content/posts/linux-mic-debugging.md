---
title: "Linux Microphone Debugging: When PipeWire Lies to You"
date: 2025-01-15
type: note
slug: linux-mic-debugging
published: true
description: "Quick reference for debugging microphone access issues on modern Linux desktops running PipeWire."
tags: ["linux", "pipewire", "audio", "debugging"]
draft: false
---

# The Problem

PipeWire reports devices as available. Applications claim to be recording. No audio is captured. This is the debugging sequence that actually works.

# Step 1 — Verify the device exists at the kernel level

```bash
arecord -l
# List all capture hardware devices
# If empty: driver issue, not PipeWire
```

# Step 2 — Check PipeWire sees it

```bash
pw-cli list-objects | grep -A5 "Audio/Source"
# Should show your capture device
```

# Step 3 — Check WirePlumber routing

```bash
wpctl status
# Look at Sources section
# Active source should have [vol: 1.00] not [vol: 0.00]
```

# Step 4 — Test capture directly via PipeWire

```bash
pw-record --target=<node-id> test.wav
# Get node-id from wpctl status output
# Record 5 seconds, play back with pw-play test.wav
```

# Step 5 — Check permissions

```bash
ls -la /dev/snd/
# Your user needs to be in the audio group
groups $USER | grep audio
# If not: sudo usermod -aG audio $USER && reboot
```

# Common Culprits

- WirePlumber defaulting to wrong capture node after suspend/resume
- Volume set to 0.00 at the WirePlumber layer despite mixer showing 100%
- PipeWire session manager not running (`systemctl --user status pipewire-session-manager`)
- Flatpak app sandboxed away from real audio devices

**Note**  
On Fedora, the session manager is `wireplumber`. On some distros it may be `pipewire-media-session`. Check which is active before debugging the wrong daemon.
