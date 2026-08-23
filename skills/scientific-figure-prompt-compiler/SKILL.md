---
name: scientific-figure-prompt-compiler
description: Transform concise scientific or technical descriptions into structured visual specifications and high-quality image-generation prompts. Use for scientific figures, technical diagrams, system architectures, mechanisms, workflows, spatial models, timelines, layered systems, and information-dense visuals. Model-agnostic; adapt the final prompt for Nano Banana or another image model.
---

# Scientific Figure Prompt Compiler

## Purpose

Act as a visual reasoning and prompt-compilation skill. Do not directly translate the user's words into an image prompt. Compile:

`User intent → Scientific/technical meaning → Visual Specification → Image-generation prompt`

The Visual Specification is the intermediate representation between human language and the image model.

## When to use

Use when the user asks to create or visualize:
- scientific figures
- research concepts or mechanisms
- technical diagrams
- system architectures
- workflows and processes
- spatial or layered systems
- timelines or lifecycles
- causal relationships
- sketches/reference images converted into professional figures
- publication-ready technical illustrations

Do not use for ordinary decorative image generation where information structure is not important.

---

# Pipeline

Always reason through:

1. Intent Analysis
2. Entity Extraction
3. Relationship Extraction
4. Structural Modeling
5. Composition Planning
6. Visual Representation
7. Visual Hierarchy
8. Style / Color / Label Definition
9. Constraint and Accuracy Check
10. Visual Specification
11. Final Image Prompt

Do not expose hidden reasoning. Return the resulting specification and prompt, not chain-of-thought.

---

# 1. Intent Analysis

Identify:

- **Subject:** What is the figure about?
- **Primary message:** What should the viewer understand after seeing it?
- **Context:** What research, engineering, product, or technical context does it belong to?
- **Audience:** publication, presentation, documentation, technical explanation, product communication, or educational material.

Express the central idea as:

`[X] affects/interacts with/transforms [Y] through [Z].`

Do not invent scientific claims.

# 2. Entity Extraction

Extract meaningful entities and classify them as:

- Primary object
- Secondary object
- Component
- Input
- Output
- Actor
- Process
- State
- Variable
- Environment
- Measurement
- Event
- Constraint

For each important entity determine its role, importance, likely visual representation, and relationships. Do not add entities merely because they are common in the domain.

# 3. Relationship Extraction

Identify relationships such as:

- causes / affects
- activates / inhibits
- binds / transforms / transports
- contains / surrounds / overlaps
- precedes / follows
- increases / decreases
- branches / converges
- feeds back / depends on
- modulates / filters / maps / controls

Represent important relationships explicitly:

- activation → directional arrow
- inhibition → blunt-ended connector
- temporal sequence → timeline / sequential arrows
- containment → nested boundary
- spatial relation → position / distance / region
- modulation → input arrow
- feedback → loop
- dependency → directed connector

Do not rely on proximity alone for important relationships.

# 4. Structural Modeling

Choose the appropriate structure, possibly combining several:

- **Spatial:** radial field, map, coordinate plane, concentric rings, zones, anatomical layout, layered field
- **Temporal:** timeline, event sequence, lifecycle, state transition, temporal bands
- **Causal:** A → B → C
- **Hierarchical:** System → Layer → Component → Subcomponent
- **Comparative:** control vs treatment, before vs after, normal vs abnormal
- **Network:** nodes and edges, pathways, dependency graphs
- **Process:** Input → Processing → Output
- **Hybrid:** combine structures when necessary

Do not force a complex concept into one diagram type if a hybrid communicates it better.

# 5. Composition Planning

Define:

- canvas orientation
- primary focal point
- secondary regions
- reading direction
- information hierarchy
- grouping
- whitespace
- supporting annotations

Use explicit spatial instructions such as:

- Place the primary system at the center.
- Arrange the process from left to right.
- Place external inputs above the main system.
- Place the timeline beneath the main diagram.
- Use a magnified inset on the right.
- Separate experimental conditions into aligned panels.

Every major region must have a communicative purpose.

# 6. Visual Representation

Translate abstract information into visual primitives:

| Concept | Representation |
|---|---|
| Spatial intensity | gradient / density / rings |
| Time | timeline |
| Sequence | arrows / numbered stages |
| Causality | directional arrows |
| Inhibition | blunt-ended connector |
| Activation | arrow |
| Hierarchy | nested containers |
| Magnitude | scale / thickness |
| Continuous change | curve / gradient |
| Discrete event | marker / node |
| Range | band |
| Boundary | outline / region |
| Comparison | parallel panels |
| Feedback | loop |
| Modulation | input connector |
| State | distinct visual state |

Prefer explicit technical representations over decorative metaphors.

# 7. Visual Hierarchy

Define:

- **Primary:** noticed first
- **Secondary:** required to understand the primary concept
- **Tertiary:** labels, legends, annotations, context

Establish hierarchy through scale, position, contrast, whitespace, line weight, color, and density. Do not make every element equally prominent.

# 8. Color and Style

Default style:

`clean, professional, publication-ready scientific or technical illustration`

Prefer precise geometry, consistent line weights, restrained colors, clean backgrounds, readable labels, and controlled visual density.

Use color semantically when appropriate. Example:
- blue = baseline / stable
- orange = active / selected
- red = abnormal / inhibited / harmful
- green = successful / recovered
- gray = neutral context

Avoid generic AI-art aesthetics, excessive photorealism, cinematic lighting, unnecessary 3D effects, ornamental decoration, and visual clutter unless explicitly requested.

# 9. Reference Images

Classify each reference as:

1. content reference
2. structural reference
3. style reference
4. layout reference
5. combination

For a **style reference**, preserve color palette, illustration language, line weight, visual density, typography hierarchy, abstraction level, and composition principles without copying unrelated scientific content.

For a **structural reference**, preserve spatial relationships, hierarchy, panel organization, flow, and relative positions.

For a **content reference**, preserve scientifically meaningful structures while adapting them to the requested concept.

# 10. Existing Figure / Sketch

Distinguish:

### Enhance
Preserve scientific content, composition, labels, and relationships. Improve resolution, sharpness, line clarity, color consistency, and typography.

### Redesign
Preserve scientific meaning and essential relationships. Improve composition, hierarchy, visual clarity, information density, and aesthetics.

Never silently change scientific meaning.

# 11. Labels and Text

Prefer concise labels such as `Drug A`, `Protein B`, `ROS`, `ATP`, `Control`, `Treatment`, `Input`, `Output`.

Avoid long explanatory paragraphs inside the image. Preserve user-specified text exactly. Do not invent labels for unspecified concepts. When text matters, request clean, readable scientific typography and consistent label hierarchy.

# 12. Scientific / Technical Accuracy

Never invent mechanisms, biological structures, experimental results, causal relationships, numerical values, measurements, statistical findings, or unsupported architecture components.

If abstraction is necessary, use a schematic representation. When ambiguous, make the most conservative reasonable assumption.

# 13. Information Density

Optimize for information efficiency:

`Primary concept → major components → important relationships → supporting detail`

Remove elements that do not improve understanding. The figure should be understandable at a glance while retaining enough detail for technical interpretation.

# 14. Visual Specification

Before writing the final prompt, construct this intermediate representation:

```text
SCIENTIFIC / TECHNICAL INTENT
- Subject:
- Primary message:
- Context:
- Audience:

ENTITIES
- Primary:
- Secondary:
- Inputs:
- Outputs:
- States:
- Events:

RELATIONSHIPS
- Causal:
- Spatial:
- Temporal:
- Functional:
- Hierarchical:

VISUAL STRUCTURE
- Diagram type:
- Spatial organization:
- Temporal organization:
- Reading direction:
- Primary focal point:

COMPOSITION
- Canvas:
- Primary region:
- Secondary regions:
- Supporting regions:
- Whitespace strategy:

VISUAL LANGUAGE
- Illustration style:
- Abstraction level:
- Detail level:
- Color system:
- Line style:
- Dimensionality:

LABELS
- Required labels:
- Optional labels:

CONSTRAINTS
- Must preserve:
- Must avoid:
- Accuracy constraints:

REFERENCE
- Reference type:
- Elements to preserve:
```

Treat this as the canonical intermediate representation.

# 15. Final Image Prompt

Convert the Visual Specification into a coherent natural-language prompt.

Use this order:

1. image type
2. subject
3. primary message
4. main composition
5. major entities
6. relationships
7. spatial / temporal structures
8. visual hierarchy
9. color
10. labels
11. style
12. constraints

Start with an explicit instruction such as:

`Create a clean, publication-ready scientific/technical illustration...`

The final prompt should read like a visual art-direction brief, not raw JSON or a keyword dump.

Prefer concrete instructions:

GOOD: `Place the primary mechanism in the center and arrange the three stages from left to right.`

BAD: `Make the composition dynamic.`

GOOD: `Use blue for the baseline state and orange for the activated state.`

BAD: `Use beautiful colors.`

GOOD: `Show the causal relationship with directional arrows.`

BAD: `Make the relationships clear.`

# 16. Do Not Over-Prompt

Do not add details because they sound sophisticated. Do not introduce random laboratory equipment, unnecessary molecular structures, decorative particles, irrelevant biological details, fictional labels, unsupported mechanisms, or cinematic effects.

For every visual element ask:

`Why does this element exist?`

If it does not communicate information, remove it.

# 17. Model Adaptation

The architecture is model-agnostic.

Keep the Visual Specification stable and adapt only the final prompt layer to the requested image model.

For Nano Banana / Gemini-style image generation:
- favor explicit spatial relationships
- describe the complete composition
- explicitly state important text
- use natural-language visual instructions
- describe reference-image behavior clearly
- prioritize semantic relationships over keyword stuffing

Never change scientific intent merely because the target model has different prompting conventions.

# 18. Output Contract

When asked to create a figure prompt, return:

## Visual Specification
```text
[structured specification]
```

## Image Generation Prompt
```text
[final prompt optimized for the requested image model]
```

## Assumptions
Only include when ambiguity materially affects the figure. Do not ask unnecessary clarification questions. Make conservative assumptions and continue when possible.

# 19. Quality-Control Checklist

Before returning, verify:

### Meaning
- primary message explicit
- all important entities represented
- important relationships represented visually

### Structure
- appropriate diagram type
- clear reading direction
- obvious focal point
- logical composition

### Visual
- semantic colors
- clear hierarchy
- appropriate abstraction/detail
- controlled density

### Text
- concise labels
- exact preservation of required text
- no unsupported labels

### Accuracy
- no invented claims
- no changed causal relationships
- no unnecessary scientific specificity

### Generation
- model can understand major element placement
- relationships explicitly described
- constraints are clear
- no conflicting instructions

# Core Principle

> Do not translate words directly into images. Translate meaning into visual structure, then translate visual structure into an image-generation prompt.

The goal is not to make prompts longer. The goal is to make visual intent explicit.
