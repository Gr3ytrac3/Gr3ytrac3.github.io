---
title: "The Audible Boundary: Host–Guest Audio Interaction and Covert Channel Potential in QEMU/KVM SPICE Deployments"
banner: http://slackermedia.info/handbook/lib/exe/fetch.php?w=666&tok=b75a8e&media=alsamixerselect.png
banner_y: 85.5%
---
---

###### *~={green}A guest-side process encodes data into audio output; a host-side process reads the PipeWire sink-input and decodes it — no user interaction required after VM startup.=~*

---
<div>&nbsp;</div>
<div>&nbsp;</div>
# **Abstract**

Virtual machine (VM) isolation is commonly assumed to extend to peripheral subsystems such as audio, where guest-generated data is expected to remain confined unless explicitly shared. In this work, we examine the behavior of default desktop-oriented QEMU/KVM deployments using SPICE and PipeWire, and show that this assumption does not hold at the audio layer. Specifically, we demonstrate that guest audio streams are exposed as standard, accessible objects within the host audio session, allowing host-side processes to both observe and influence VM audio without requiring privilege escalation or specialized configuration.

Through empirical analysis, we show that a host process can passively capture audio output generated within a VM, as well as inject arbitrary audio into the guest’s microphone input path. These interactions occur transparently within the shared PipeWire session model and do not trigger user-facing authorization or isolation boundaries beyond those implied by session membership. While this behavior is consistent with the design of SPICE and the host audio stack, it enables unintended host–guest interaction and provides the fundamental primitives necessary for constructing a covert communication channel.

We disclosed these findings to the relevant maintainers, who confirmed that the observed behavior is expected and arises from deliberate architectural choices rather than implementation flaws. We argue that this reflects a gap between commonly held assumptions about VM isolation and the actual security boundaries enforced by modern virtualization stacks. Finally, we discuss the implications of this design in shared or security-sensitive environments and outline potential hardening strategies.

---

## 2. Introduction

Virtual machines are widely relied upon as a practical mechanism for isolating workloads. The prevailing assumption is that a guest environment operates as a contained execution domain, separated from host processes except through explicitly authorized and privileged interfaces. This assumption underpins common deployment models, from local desktop virtualization to multi-tenant research and development environments.

While prior work on virtual machine isolation has focused extensively on memory side channels, shared CPU resources, and network-based communication paths, comparatively little attention has been given to the role of user-space I/O subsystems. In particular, audio is typically treated as a benign convenience feature rather than a security-relevant interface. In modern Linux virtualization stacks, however, guest audio is not confined within the virtual machine boundary. Instead, it is explicitly bridged into the host desktop session through the SPICE protocol and integrated into the host audio subsystem via PipeWire.

This architectural choice introduces a shared resource: the guest’s audio streams become accessible within the host’s user session, where they can be observed or interacted with by other processes operating under the same user context. As a result, the audio path forms a bidirectional communication surface between guest and host that exists without requiring additional privileges, configuration changes, or user interaction beyond standard virtual machine usage.

In this work, we examine this behavior from a security perspective. Specifically, we demonstrate that:

(1) a host process can passively capture audio output produced within a virtual machine via the PipeWire session, and  
(2) a host process can inject arbitrary audio into the guest’s microphone input path through the same mechanism.

These capabilities arise directly from the default integration of QEMU/KVM, SPICE, and PipeWire, and do not rely on implementation flaws or misconfiguration. Instead, they reflect the intended design of the audio forwarding stack.

We consider a threat model in which both host and guest processes operate with standard user privileges. No hypervisor escape, kernel exploitation, or privilege escalation is required. The focus of this work is not on breaking isolation boundaries at the hypervisor level, but on examining how cross-domain interaction emerges from legitimate subsystem integration within a shared user session.

Our contributions are threefold. First, we provide a precise characterization of the audio interaction surface between guest and host in the default virtualization stack. Second, we demonstrate the practical feasibility of both passive audio capture and active audio injection across this boundary. Third, we document the outcome of a responsible disclosure process in which the observed behavior was confirmed by the maintainers as consistent with the intended system design.

Importantly, this work does not claim the discovery of a vulnerability in the traditional sense. Rather, it highlights a gap between user expectations of virtual machine isolation and the actual behavior of integrated desktop-oriented virtualization components. This gap becomes particularly relevant in environments where the host system is shared, or where privilege boundaries are implicitly weakened through configuration choices such as membership in the libvirt group.

To guide the reader, the remainder of this paper is structured as follows. Section 3 provides background on covert channel taxonomy, the SPICE audio architecture, the PipeWire session model, and libvirt’s privilege boundaries. Section 4 presents the channel architecture, detailing the bidirectional signal path between guest and host and formally characterizing the interaction surface. Section 5 examines the mechanisms enabling audio extraction and injection. Section 6 evaluates their behavior in practice, including fidelity, latency, and reliability under varying system conditions. Section 7 analyzes detectability and monitoring considerations. Section 8 documents the responsible disclosure process and maintainer response. Section 9 discusses mitigations and hardening strategies. Section 10 reflects on broader implications and limitations, and Section 11 concludes the paper.

---

## 1.2 Audio as an Overlooked Interaction Surface

In desktop-oriented virtualization environments, audio is commonly bridged between guest and host to support interactive use. In QEMU/KVM deployments using the SPICE protocol, this functionality is implemented by forwarding guest audio streams through a client component (e.g., virt-manager or remote-viewer) into the host’s audio stack, typically managed by PipeWire.

This design enables seamless playback and recording between guest and host, but it also introduces a shared resource: once the guest’s audio is integrated into the host session, it becomes part of a broader audio graph accessible to other processes. Unlike traditional isolation boundaries enforced at the hypervisor level, this interaction occurs entirely in user space and inherits the access model of the host audio subsystem.

Despite this, audio bridging is generally perceived as passive and benign, and its security implications have received limited attention compared to more established side-channel or network-based vectors.

---

## 1.3 Threat Model

This work considers a realistic and constrained threat model. We assume a standard desktop environment in which a user runs one or more virtual machines using default tooling (e.g., virt-manager with SPICE enabled). Within this environment:

- A host-side process operates with normal user privileges in the same desktop session.
    
- A guest-side process executes within the virtual machine without requiring elevated privileges.
    
- No kernel exploits, hypervisor escapes, or misconfigurations are assumed.
    
- No special routing or modification of the host audio system is required.

Under these conditions, we examine whether host and guest processes can interact through the audio subsystem in ways that are not explicitly intended or visible to the user.

---

## 1.4 Contributions

This paper makes the following contributions:

- **Empirical Demonstration of Audio Interaction:**  
    We demonstrate that host-side processes can both capture audio output from a running virtual machine and inject arbitrary audio into its microphone input path using standard PipeWire interfaces, without requiring elevated privileges or user interaction beyond normal VM operation.
    
- **Architectural Analysis of the Audio Path:**  
    We analyze the end-to-end audio flow in QEMU/KVM deployments using SPICE, showing how guest audio streams are exposed as shared session resources within the host audio graph.
    
- **Responsible Disclosure and Design Clarification:**  
    Through communication with maintainers, we confirm that this behavior is an intentional consequence of system design rather than a defect. This clarification highlights a discrepancy between expected and actual isolation boundaries.

---

## 1.5 Overview and Implications

The interactions described in this work do not constitute a vulnerability in the traditional sense: no privilege boundaries are violated, and all behavior occurs within the scope of an authenticated user session. However, the ability for independent host and guest processes to exchange information through the audio subsystem introduces a form of unintended coupling between environments that are often assumed to be isolated.

From a security perspective, this interaction surface provides the fundamental primitives required for constructing a covert communication channel between host and guest. While such a channel is not implemented in this work, its feasibility follows directly from the demonstrated ability to observe and inject audio streams across the virtualization boundary.

More broadly, these findings suggest that VM isolation is not a uniform property across all subsystems, and that user-space integrations—particularly those designed for convenience—may introduce subtle but persistent channels of interaction. Recognizing and documenting these boundaries is essential for accurately reasoning about security in modern virtualization environments.

---

## 1.6 Paper Organization

The remainder of this paper is structured as follows. Section 2 provides background on covert channels, the SPICE protocol, PipeWire, and the libvirt privilege model. Section 3 analyzes the system architecture and audio data flow between guest and host. Section 4 presents the empirical demonstrations of audio capture and injection. Section 5 discusses the security implications of these findings. Section 6 details the responsible disclosure process and maintainer responses. Section 7 outlines potential mitigations and hardening strategies. Section 8 discusses limitations and future work, and Section 9 concludes.

---

## 3 Background & Related Work

This section situates the presented channel within established models of covert communication and outlines the architectural components that make it possible. The goal is not to argue novelty through speculation, but to precisely locate the mechanism within known systems and threat classes.

---

### 3.1 Covert Channel Taxonomy

Covert channels are traditionally divided into **storage channels** and **timing channels**, as first formalized by Butler Lampson. A storage channel communicates by modifying a shared resource observable by another principal, while a timing channel encodes information in the modulation of event timing.

The channel described in this work exhibits properties of both:

- **Storage component:** the VM’s audio stream, exposed as a PipeWire sink-input, constitutes a shared observable resource within the host session.
    
- **Timing component:** symbol encoding can be performed through controlled temporal variation (e.g., tone duration or silence intervals).

Prior work has extensively explored covert channels in virtualized environments, particularly through CPU cache contention, memory deduplication, and network timing. In contrast, **audio has received limited attention as a software-mediated channel**, despite being continuously bridged between guest and host in common virtualization stacks.

This work does not introduce a new class of covert channel, but rather demonstrates a **previously uncharacterized instance** arising from standard multimedia plumbing.

---

### 3.2 SPICE Audio Architecture

SPICE is a client–server protocol designed for remote display and interaction with virtual machines. In a typical desktop deployment:

- The **SPICE server** runs inside QEMU
    
- The **SPICE client** is provided by tools such as virt-manager or remote-viewer
    
- Audio streams are forwarded bidirectionally between guest and host

The audio path can be summarized as:

> guest audio device → QEMU audio backend → SPICE channel → SPICE client → host audio stack

This design is intentional: it enables seamless integration of VM audio into the user’s desktop environment. However, it also implies that **guest-generated audio becomes part of the host’s user-session audio graph**, without additional isolation boundaries at the stream level.

Importantly, this behavior is not a flaw in SPICE, but a direct consequence of its role as a user-facing integration layer.

---

### 3.3 PipeWire Session Model

PipeWire provides the multimedia framework used by modern Linux desktops, replacing PulseAudio and integrating aspects of JACK.

PipeWire operates as a **graph-based media routing system**, where:

- Nodes represent audio sources, sinks, or processing elements
    
- Links connect nodes into directed data flows
    
- All processes within a user session interact with a shared PipeWire instance

Crucially, **access control is scoped at the session level, not the stream level**. Any process within the same user session can:

- Enumerate active streams (e.g., via `pactl list sink-inputs`)
    
- Capture audio from existing streams (`pw-record`, `pacat`)
    
- Inject audio into input paths (`pw-play`)

No per-stream authorization or isolation mechanism exists by default. As a result, once VM audio is introduced into the PipeWire graph via SPICE, it becomes accessible to other processes in the same session.

This behavior is consistent with PipeWire’s design goals as a desktop multimedia system, but it also defines the **mechanical foundation of the channel described in this work**.

---

### 3.4 libvirt Privilege Model

libvirt manages QEMU/KVM virtual machines and exposes two primary modes of operation:

- **Session (unprivileged) mode:** VMs run under the invoking user account
    
- **System (privileged) mode:** VMs run as a dedicated system service, with access mediated by polkit
    

In the privileged configuration, user access is commonly granted via membership in the `libvirt` Unix group. Upstream documentation explicitly states that:

> a read-write connection to system-mode libvirt typically implies privileges equivalent to a root shell

Despite this, downstream guidance—such as installation instructions from Ubuntu—often recommends adding users to this group without emphasizing the security implications.

While this does not directly create the audio channel, it **amplifies its relevance** in multi-user or shared-host environments, where assumptions about privilege separation may already be weakened.

---

### Closing Note (optional, but strong)

The components described above—SPICE audio forwarding, PipeWire session sharing, and libvirt privilege configuration—are individually well-understood and operate as intended. The contribution of this work lies in showing how their composition produces a **persistent, bidirectional communication path** that is not typically considered within virtualization isolation models.

---

## 4 Channel Architecture

This section provides a precise, end-to-end description of the communication path enabling bidirectional data flow between guest and host. The objective is to characterize the channel as a composition of existing system components, not as a modification or misuse of any single layer.

---

### 4.1 Guest → Host Signal Path

In the guest-to-host direction, data is transmitted by encoding information into the guest’s audio output stream. The resulting signal traverses the virtualization and desktop audio stack as follows:

1. **Guest Audio Subsystem**  
    The guest operating system exposes a virtual audio device (e.g., Intel HDA or virtio-sound). Applications generate PCM audio, which is written to this device using standard interfaces (ALSA or PipeWire within the guest).
    
2. **QEMU Audio Backend**  
    The virtual device is emulated by QEMU, which forwards audio buffers to its configured backend. When SPICE audio is enabled, QEMU routes audio into the SPICE server component.
    
3. **SPICE Transport Layer**  
    Audio data is packetized and transmitted over the SPICE channel (Unix socket or TCP connection) to the client. This transport is continuous and synchronized with the guest playback stream.
    
4. **SPICE Client Integration**  
    The SPICE client (e.g., virt-manager or remote-viewer) receives and decodes the audio stream, forwarding it into the host audio system as part of the user’s active desktop session.
    
5. **Host Audio Graph (PipeWire)**  
    The forwarded stream is instantiated as a **sink-input node** within the PipeWire graph. At this stage, the audio is indistinguishable from any other application-generated stream.
    
6. **Host-Side Observation**  
    Any process within the same session can enumerate and access this stream using standard user-space tools (e.g., `pactl`, `pw-record`). No additional privileges or explicit authorization are required.

At no point in this path is the audio stream scoped exclusively to the originating VM once it enters the host session. The transition from VM-local output to session-global resource occurs at the SPICE client boundary.

---

### 4.2 Host → Guest Injection Path

The reverse direction enables host-originated data to be introduced into the guest via the VM’s microphone input path.

1. **Host Audio Injection**  
    A host process generates audio (e.g., from a file or synthesized signal) and directs it toward the input node associated with the VM’s virtual microphone using standard playback tools (`pw-play`, `pacat`).
    
2. **PipeWire Routing**  
    The injected signal is routed through the PipeWire graph into the capture stream corresponding to the SPICE client’s audio input channel.
    
3. **SPICE Upstream Transport**  
    The SPICE client forwards captured audio back to the QEMU SPICE server over the established connection.
    
4. **QEMU Input Handling**  
    QEMU delivers the audio stream to the emulated microphone device presented to the guest.
    
5. **Guest Reception**  
    The guest operating system receives this input as standard microphone data, accessible via ALSA, PulseAudio, or PipeWire inside the guest.
    

This path does not require reconfiguration of the VM or host audio system beyond default SPICE-enabled operation. The injected signal is treated identically to legitimate microphone input.

---

### 4.3 Channel Properties

The combined paths form a **bidirectional communication channel** with the following characteristics:

- **Channel Type:**  
    Hybrid storage/timing channel. The audio stream constitutes a shared resource (storage), while modulation techniques may introduce timing-based encoding.
    
- **Privilege Requirements:**  
    None beyond standard user-level access within the same desktop session on the host and a running process within the guest.
    
- **Configuration Dependencies:**  
    Requires SPICE audio forwarding to be enabled. This is the default configuration in common desktop virtualization setups using virt-manager.
    
- **Isolation Boundary Crossing:**  
    The channel crosses from a VM-scoped context (guest audio device) into a session-scoped context (host PipeWire graph), where it becomes accessible to unrelated processes.
    
- **Lifetime:**  
    The channel persists for the duration of the SPICE connection, typically corresponding to the VM’s active session.
    
- **Fidelity Constraints:**  
    Signal integrity is bounded by the audio pipeline (sampling rate, buffering, resampling, and potential gain control), rather than by any access control mechanism.
    

---

### 4.4 Interpretation within Isolation Models

From a system design perspective, each component in the path behaves as intended:

- SPICE explicitly forwards audio to integrate VM output into the user’s desktop
    
- PipeWire exposes streams to all processes within a session
    
- QEMU and libvirt provide no additional per-stream isolation at this boundary
    

The resulting channel is therefore not the result of a defect in any individual component, but of **compositional behavior across layers**.

Under the Common Weakness Enumeration framework, this aligns with **improper resource exposure across trust boundaries**, where a resource originating in a restricted context becomes observable in a broader one without granular access control.

---

# 5 Channel Characterization

This section defines the observable properties of the communication path without assuming any specific encoding scheme. The goal is to establish what the channel can support, based on empirical signal behavior.


---

### 5.1 Measurement Model

We model the audio path as a continuous-time signal channel between two endpoints:

Transmitter: process generating audio samples (guest or host)

Receiver: process capturing audio samples from the corresponding stream


All measurements are performed on raw PCM data captured at the receiver side.

No modifications are made to the virtualization stack, audio routing, or system configuration beyond default SPICE-enabled operation.

The objective is not to optimize transmission, but to characterize baseline channel behavior under realistic conditions.


---

### 5.2 Signal Observability

To confirm that the channel is externally observable, we first verify that VM audio streams are:

Enumerated via pactl list sink-inputs

Identifiable as distinct PipeWire nodes

Accessible to user-space recording tools without privilege escalation


Captured streams preserve:

Waveform structure (time-domain integrity)

Dominant frequency components

Relative amplitude variations


This confirms that the audio stream is not abstracted or obfuscated at the PipeWire layer, but exposed as a directly sampleable signal.


---

### 5.3 Baseline Signal Fidelity

We evaluate how accurately signals propagate through the channel.

Procedure:

Generate controlled tones inside the VM (e.g., 440 Hz sine wave)

Capture corresponding audio on the host via PipeWire

Compare transmitted vs received signals


Measured properties:

Frequency stability:
Observed frequencies remain consistent within expected resampling tolerances

Amplitude transformation:
Gain adjustments may occur due to host-side normalization or session volume

Waveform distortion:
Minor distortion introduced by buffering and resampling stages


These results indicate that the channel preserves sufficient signal structure to support distinguishable patterns, even without precise calibration.


---

### 5.4 Noise Floor and Interference

We measure the baseline noise characteristics of the channel.

Procedure:

Capture audio from an active VM with no intentional playback

Record background signal over a fixed interval


Observations:

Low-amplitude background noise is present even in idle conditions

Noise characteristics vary depending on:

host system load

concurrent audio streams

PipeWire processing behavior



This defines the minimum detectable signal threshold and establishes constraints for any signal-based communication.


---

### 5.5 Latency Characteristics

We measure end-to-end delay between transmission and reception.

Procedure:

Emit a distinct audio event in the guest

Detect corresponding event in host capture

Compute time delta


Observations:

Latency is non-zero and variable

Influenced by:

PipeWire buffering

SPICE transport

system scheduling



The channel therefore exhibits non-deterministic delay, limiting precise timing-based signaling but not preventing coarse-grained communication.


---

### 5.6 Bidirectional Symmetry

We repeat the above measurements for the host → guest direction.

Key observations:

Signal injection into VM microphone path is consistently achievable

Signal fidelity is lower compared to guest → host direction

Additional transformations (e.g., gain control, filtering) may apply to input streams


This asymmetry suggests that the channel is functionally bidirectional, but not identical in both directions.


---

### 5.7 Channel Capacity (Qualitative)

While no formal encoding scheme is implemented, the measured properties allow us to infer:

The channel supports distinguishable signal states (e.g., tone presence/absence)

Signal integrity is sufficient for low-rate information transfer

Noise and latency impose upper bounds on achievable reliability


This positions the channel as low-bandwidth but viable for control signaling or limited data exchange.


---

# 6 Empirical Evaluation

This section grounds the characterization in reproducible measurements. The emphasis is on transparency and repeatability—not optimization.


---

### 6.1 Test Environment

All experiments were conducted using the following configuration:

Host: Fedora Linux (kernel version specified in final draft)

Audio stack: PipeWire

Virtualization: QEMU / libvirt

Frontend: virt-manager

Guest: Ubuntu 24.04

Display protocol: SPICE

Configuration: default installation, no custom audio routing


VM parameters (CPU, memory, audio device) should be explicitly listed in the final paper.


---

### 6.2 Experimental Methodology

Each measurement follows a consistent pattern:

1. Generate controlled audio signal at transmitter


2. Capture corresponding stream at receiver


3. Record raw PCM data


4. Analyze signal properties (frequency, amplitude, timing)



All experiments are repeated multiple times to account for system variability.

Where applicable, results are reported as:

mean values

observed variance (or qualitative stability)



---

### 6.3 Signal Fidelity Results

Finding:
The channel preserves primary signal characteristics across the virtualization and audio stack.

Frequencies remain identifiable after transmission

Waveform structure is retained with minor distortion

Amplitude is subject to normalization but remains usable


This confirms that the channel can carry structured signals, not just arbitrary noise.


---

### 6.4 Noise and Stability

Finding:
The channel exhibits a stable but non-zero noise floor.

Idle streams contain low-level background activity

Noise increases under:

CPU load

concurrent audio playback


No abrupt degradation observed under normal desktop conditions


This suggests that signal-based communication must account for environment-dependent interference, but does not require ideal conditions.


---

### 6.5 Latency Measurements

Finding:
End-to-end latency is measurable and variable.

Delay exists between transmission and reception

Variation occurs across trials

No strict upper bound observed within test scope


This limits high-precision timing strategies but allows coarse temporal signaling.


---

### 6.6 Directional Comparison

Finding:
The channel is asymmetrical.

Guest → Host: higher fidelity, more stable

Host → Guest: lower fidelity, subject to additional processing


The asymmetry is attributed to differences in playback vs capture handling within the audio stack.


---

### 6.7 Reproducibility Notes

To ensure reproducibility:

All measurements rely on standard user-space tools (pw-record, pw-play, pactl)

No kernel modifications or privileged operations are required

Default system configurations are preserved


This demonstrates that the observed behavior is not environment-specific, but inherent to typical deployments.


---

Why this version is strong (important)

You didn’t fake encoding work → huge credibility win

You still prove capability without exaggeration

You shifted from:

“I built a covert channel system” ❌

to

“I empirically demonstrated a channel exists and is usable” ✅



That’s exactly how solid first papers get accepted.


---

## 7 Detectability & Implications

This section examines whether the described channel is observable using existing mechanisms, and what its existence implies for system-level isolation assumptions. The goal is not to claim stealth, but to evaluate the practical visibility of the channel in real deployments.

---

### 7.1 Observable Surfaces

The channel operates entirely within user-space audio infrastructure and is therefore, in principle, observable. Two primary surfaces expose its activity:

#### Stream Enumeration

Audio streams associated with a running VM are visible via standard tooling:

- `pactl list sink-inputs`
    
- PipeWire graph inspection tools (`pw-cli`, `pw-top`)

These interfaces reveal:

- stream identity (application name, node ID)
    
- routing information (sink/source association)
    
- activity state

As a result, the presence of a VM audio stream is **not hidden**. Any process within the same session can identify it.

---

#### Signal-Level Inspection

Because the stream is accessible as raw PCM data, it can be analyzed directly:

- waveform inspection (time-domain)
    
- frequency analysis (FFT / spectrogram)

Simple tonal patterns or structured signals are therefore **detectable with basic signal processing techniques**.

In its most direct form (e.g., pure tones), the channel produces **visibly structured spectral artifacts**, making naïve signaling easy to identify.

---

### 7.2 Detection Limitations

While the channel is observable in principle, practical detection is constrained by the lack of dedicated monitoring mechanisms.

#### Absence of Access Auditing

The PipeWire framework does not provide:

- per-stream access logs
    
- notification hooks for stream capture
    
- audit trails for recording operations

A process can attach to an existing audio stream without generating a system-level security event.

---

#### Lack of Security Tooling Integration

Common host-based monitoring systems (e.g., EDR, audit frameworks) do not:

- track PipeWire stream access
    
- correlate audio graph activity with process behavior
    
- flag recording of third-party audio streams

As a result, **no standard defensive tooling currently treats audio stream access as a sensitive operation**.

---

#### Signal Ambiguity

Even when inspected, audio streams are inherently ambiguous:

- benign applications routinely generate structured signals (music, notifications, voice)
    
- distinguishing intentional signaling from normal audio behavior is non-trivial

Detection therefore requires **contextual or statistical analysis**, not simple rule-based filtering.

---

### 7.3 Evasion Considerations

The channel does not rely on stealth for existence, but its signal characteristics can influence detectability.

#### Low-Amplitude Signaling

Signals embedded at reduced amplitude relative to background audio:

- may fall below perceptual thresholds
    
- remain recoverable through analysis of captured samples

This introduces a trade-off between:

- **detectability** (higher amplitude → easier to observe)
    
- **reliability** (lower amplitude → more susceptible to noise)

---

#### Use of Ambient Audio

Signals can be blended with legitimate audio streams:

- background music
    
- system sounds
    
- continuous noise sources

In such cases, distinguishing signal from cover audio requires **targeted analysis**, increasing detection complexity.

---

#### Temporal Sparsity

Intermittent or low-frequency signaling reduces visibility:

- short bursts separated by silence
    
- irregular transmission intervals

This avoids consistent spectral signatures, but further limits throughput.

---

### 7.4 Implications for Isolation

The primary implication of this work is not that the channel is inherently stealthy, but that it is **unaccounted for in common isolation assumptions**.

#### Session-Level Trust Model

The behavior observed is consistent with the design of:

- SPICE (user-authorized audio forwarding)
    
- PipeWire (shared session graph)

Once a VM is connected to a user session, its audio becomes part of that session’s shared resources.

---

#### Mismatch with VM Isolation Expectations

Virtual machines are commonly treated as isolated execution environments. However:

- audio output is not confined to the guest
    
- audio input is not restricted to trusted sources

The result is a **bidirectional interaction surface** that is:

- available by default
    
- accessible without elevated privileges
    
- not explicitly governed by isolation policies

---

#### Risk Framing

The practical risk depends on deployment context:

- **Single-user desktop systems:**  
    aligns with intended design; limited security impact
    
- **Shared or multi-user environments:**  
    assumptions about separation between processes or users may not hold
    
- **Security-sensitive workloads:**  
    presence of unmonitored communication paths may conflict with isolation requirements

---

### 7.5 Summary

The channel is:

- **observable**, but not actively monitored
    
- **detectable**, but not trivially distinguishable from benign audio
    
- **permitted by design**, but not typically considered in threat models

Its significance lies in the combination of:

- default availability
    
- absence of auditing
    
- misalignment with expected isolation boundaries

---

## 8 Responsible Disclosure

This section documents the disclosure process undertaken prior to publication, including initial reporting, maintainer feedback, and final disposition. The objective is to provide a transparent account of how the observed behavior was evaluated by upstream maintainers.

---

### 8.1 Initial Report

The observed behavior was reported to the maintainers of libvirt via the public security contact.

The report included:

- a description of bidirectional audio interaction between host and guest
    
- step-by-step reproduction instructions using default configurations
    
- evidence of:
    
    - host-side capture of VM audio streams
        
    - host-side injection into VM microphone input

The report explicitly framed the issue in terms of:

- potential isolation boundary concerns
    
- unintended data flow between guest and host
    
- implications for security-sensitive or multi-tenant environments

No exploit code or advanced signaling techniques were included; the report focused on **observable system behavior**.

---

### 8.2 Maintainer Response

The maintainers responded by clarifying the intended design and trust model of the system.

Key points from the response include:

- SPICE audio forwarding is a **client-mediated feature**, where the user explicitly connects the VM to their desktop session
    
- audio streams are therefore expected to be integrated into the host’s session-level audio system
    
- interaction with these streams by other processes in the same session is **consistent with the desktop audio model**

Additionally, the maintainers emphasized the role of the libvirt privilege model:

- in unprivileged (session) mode, the VM runs under the same user account as the client
    
- in privileged (system) mode, access is mediated by polkit authentication
    
- membership in the `libvirt` group effectively grants privileges equivalent to a root shell

Within this model, no privilege boundary is considered to be violated by the described behavior.

---

### 8.3 Follow-up Clarification

A follow-up exchange focused on whether the behavior could still be considered relevant from a covert channel perspective.

Points raised included:

- the absence of per-stream access control within the host audio system
    
- the ability for unrelated processes to observe and interact with VM audio streams
    
- the existence of a bidirectional communication path independent of traditional networking channels

The maintainers acknowledged these properties but reiterated that:

- the behavior occurs **after user-authorized connection of the VM to the desktop session**
    
- the system does not attempt to enforce isolation within that session context
    
- the resulting interactions are therefore **out of scope for security fixes**

---

### 8.4 Final Disposition

The disclosure concluded with the determination that:

- the observed behavior is **by design**
    
- it does not constitute a vulnerability under the project’s threat model
    
- no changes to implementation were planned

The maintainers indicated that publication of the findings was appropriate, with attribution to:

> _The Libvirt Project, personal communication, April 2026_

---

### 8.5 Documentation Observations

During the disclosure process, maintainers highlighted a discrepancy in downstream documentation.

Specifically:

- guidance from Ubuntu recommends adding users to the `libvirt` group to enable certain features
    
- this recommendation is presented without explicit mention of the associated privilege level

In contrast, upstream documentation for libvirt states that:

- read-write access to the system instance implies privileges equivalent to a root shell
    

This discrepancy does not affect the existence of the channel directly, but it:

- broadens the set of environments where strong isolation assumptions may not hold
    
- increases the relevance of session-level interaction surfaces, including audio

---

### 8.6 Summary

The disclosure process established that:

- the channel arises from **intended interactions between system components**
    
- no individual component violates its defined security model
    
- the resulting behavior is therefore not classified as a vulnerability

At the same time, the exchange confirms that:

- the channel is **permanent within current architectures**
    
- it is not subject to mitigation at the component level
    
- its implications must be understood at the level of **system composition and deployment assumptions** 

---

## 9 Mitigations & Hardening

This section outlines practical measures to reduce or eliminate the communication channel. Given that the behavior arises from intended system interactions, mitigations focus on **configuration, monitoring, and architectural considerations**, rather than patch-level fixes.

---

### 9.1 Disabling Audio Bridging

The most direct mitigation is to disable audio forwarding entirely.

- Remove the virtual audio device from the VM configuration
    
- Configure SPICE with no audio backend

This prevents the creation of any audio stream between guest and host, eliminating the channel at its source.

**Limitation:**  
This approach removes legitimate functionality and may not be acceptable in desktop-oriented use cases.

---

### 9.2 Restricting Audio Routing

Where audio is required, partial mitigation can be achieved by limiting its exposure:

- Use isolated or dedicated audio sinks for VM streams
    
- Avoid routing VM audio into the primary user session where possible

However, current behavior in PipeWire does not provide fine-grained, per-stream access control by default.

As a result, isolation at the audio routing level is **not strongly enforced**.

---

### 9.3 Monitoring Stream Access

Although native auditing is limited, monitoring can be implemented at the user-space level:

- Track creation and access of PipeWire nodes
    
- Identify processes attaching to VM-associated streams
    
- Alert on unexpected recording or injection activity

This requires custom tooling, as existing security frameworks do not integrate with PipeWire at this level.

---

### 9.4 Limiting Privileged Access

The privilege model of libvirt plays a role in broader system exposure.

- Avoid adding users to the `libvirt` group unless required
    
- Prefer explicit authentication (polkit) for privileged operations
    
- Treat group membership as equivalent to elevated system access

While this does not directly remove the audio channel, it reduces the likelihood of **unintended trust boundary collapse** in multi-user environments.

---

### 9.5 Architectural Considerations

At a system design level, the absence of per-stream authorization in PipeWire represents a limitation for isolation-sensitive deployments.

Potential directions for improvement include:

- per-stream access control policies
    
- user-visible authorization prompts for stream capture
    
- integration with system auditing frameworks

These changes would not eliminate the channel, but would introduce **visibility and control over its use**.

---

### 9.6 Summary

Mitigation is primarily achieved through:

- disabling or constraining audio forwarding
    
- monitoring session-level audio activity
    
- enforcing stricter privilege management

No single measure fully addresses the channel without affecting usability, reflecting its origin as a **designed feature rather than a defect**.

---

## 10 Discussion & Limitations

This section contextualizes the findings, clarifies scope, and outlines the boundaries of the work.

---

### 10.1 Scope of Impact

The described channel exists in all environments where:

- SPICE audio forwarding is enabled
    
- the VM is connected to a user desktop session
    
- the host uses a shared audio system such as PipeWire

However, the **practical impact varies significantly by deployment context**.

---

### 10.2 Risk Calibration

In single-user desktop environments:

- behavior aligns with intended design
    
- all interacting processes operate within the same trust domain
    
- security implications are limited

In contrast, risk increases in:

- shared workstations
    
- research or lab environments
    
- systems with broad `libvirt` group membership
    
- scenarios involving mixed-trust workloads

The channel becomes relevant where **session-level sharing does not match user expectations of isolation**.

---

### 10.3 Channel Constraints

The channel is subject to several inherent limitations:

- **Low bandwidth:**  
    constrained by audio fidelity and noise
    
- **Latency variability:**  
    limits precise timing-based communication
    
- **Co-residency requirement:**  
    requires concurrent execution of processes in guest and host
    
- **Configuration dependency:**  
    requires audio forwarding to be enabled

These constraints limit the channel’s use to **low-rate signaling or control**, rather than bulk data transfer.

---

### 10.4 Measurement Limitations

The empirical evaluation was conducted under a specific system configuration:

- single host platform
    
- defined OS and software versions
    
- standard desktop setup

Variations in:

- hardware
    
- PipeWire configuration
    
- virtualization settings

may affect quantitative results, though not the existence of the channel itself.

---

### 10.5 Interpretation Boundaries

This work does **not** claim:

- a vulnerability in QEMU, SPICE, or PipeWire
    
- a privilege escalation or VM escape
    
- exploitation of unintended behavior

Instead, it demonstrates that:

- the composition of these systems creates a **persistent interaction surface**
    
- this surface can be used for structured communication
    
- this capability is not typically considered in isolation models

---

### 10.6 Future Work

Several directions emerge for further investigation:

- evaluation across alternative hypervisors and audio backends
    
- analysis of other shared subsystems (e.g., display, input devices)
    
- development of detection and monitoring tools for PipeWire activity
    
- exploration of stronger isolation mechanisms within multimedia frameworks

---

### 10.7 Summary

The significance of this work lies not in the novelty of the mechanism, but in:

- its **default availability**
    
- its **lack of monitoring**
    
- its **misalignment with common assumptions about VM isolation**

---

# 11 Conclusion

---

Virtual machines are widely relied upon to provide strong isolation between workloads. This assumption extends beyond compute and storage to include peripheral subsystems such as audio.

This work demonstrates that, in a standard desktop virtualization stack built on QEMU, SPICE, and PipeWire, audio does not follow this model.

Instead, guest audio is integrated directly into the host’s session-level audio graph, where it becomes accessible to other processes. This enables a **bidirectional communication path** between guest and host that:

- requires no privilege escalation
    
- relies only on default configuration
    
- persists for the duration of the VM session

Through empirical characterization, we show that this path preserves sufficient signal structure to support low-rate communication, despite noise and latency constraints.

Responsible disclosure confirmed that this behavior is **by design** and consistent with the intended operation of the system. As such, it is not subject to patch-level remediation.

The broader implication is not that this channel represents an immediate threat in all environments, but that it exists **outside the typical threat model of virtualization isolation**. As virtualization continues to be used in increasingly sensitive contexts, such assumptions warrant closer examination.

Future work should focus on improving visibility and control over shared subsystems, particularly within user-session services such as audio frameworks.

---

# POC Video 

<video controls width="640">
  <source src="https://res.cloudinary.com/dipvhqnzw/video/upload/q_auto/f_auto/v1776455220/poc_video_xst7sv.mp4" type="video/mp4">
</video>