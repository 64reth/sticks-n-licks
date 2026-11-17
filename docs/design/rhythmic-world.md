# The entire world follows the beat

Permanent owner-approved requirement, introduced with Milestone 011: every animated, moving or reactive element in Story Mode shares the existing authoritative musical conductor. The world dances to the same music without moving identically.

Gameplay events use conductor-defined beats or subdivisions. Smooth presentation interpolates between beat-defined states using the current musical phase. Environmental cycles may span different numbers of beats and use deterministic offsets. NPC gestures/dialogue reactions, vehicles, warnings, collision windows, cane and other hazards all follow this rule. Scene transitions preserve phase; pause freezes the conductor; restart/re-entry rebind to its current phase. Never add free-running world timers, random drift or another BPM clock.

`BeatWorld` is a read-only view of the existing conductor: absolute musical beat, cycle phase, pose selection and interpolation. The existing coconut palm remains unchanged. Placeholder clouds use 32 beats, palms eight, vendors four with offsets, cane eight with staggered stalk phases, traffic a 16-beat safety cycle with two-beat travel, dialogue a quarter-beat advancement boundary. Static objects need no artificial animation. No appropriate genuine unarmed breathing sequence has been found, so its approved idle remains static instead of inventing motion.

The approved one-step-per-beat fighter movement, 16-pixel displacement, 160ms step presentation, movement/combat windows, and existing combat resolution remain authoritative. Existing impact durations are preserved and sampled from conductor time; animation callbacks never award hits. A Story fight uses the existing Bout, action adapter and CPU public-observation boundary, not a separate combat implementation.

Future screens must participate through the same interfaces. The acceptance route includes player, vendors, traffic, palms, cane, interactive items and effects across all six fixed-camera screens, including pause/resume and transitions.
