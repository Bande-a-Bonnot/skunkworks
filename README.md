# Skunkworks

A cabinet of curiosities for Bande à Bonnot experiments: weird, fun, useless, interesting, unnamed, maybe-useful, maybe-not things that deserve a place to exist before anyone decides what they are.

## What Belongs Here

- Tiny prototypes and one-off scripts
- Half-ideas that need a runnable sketch
- Useless-but-fun toys
- Interesting technical spikes
- Name-finding / shape-finding explorations
- Experiments that might later graduate into their own repo

If it is already a product, library, or serious long-lived project, it probably wants its own sibling repo. If it is still strange and exploratory, put it here.

## Repository Layout

```text
.
├── AGENTS.md              # Agent/project instructions
├── docs/                  # Cross-experiment docs and handoff
│   ├── HANDOFF.md
│   ├── brainstorms/
│   ├── plans/
│   ├── runbooks/
│   └── solutions/
├── experiments/           # One nested directory per experiment
│   ├── README.md
│   └── _template/
└── todos/                 # Markdown todo records
```

## Starting a New Experiment

```bash
slug="my-weird-thing"
cp -R experiments/_template "experiments/$slug"
```

Then edit `experiments/$slug/README.md` and keep all experiment-specific files inside that directory.

A minimal experiment should answer:

1. What is this?
2. Why is it interesting/funny/useful/useless?
3. How do I run or inspect it?
4. What did we learn?
5. Should it be abandoned, kept, or graduated?

## Current Status

Freshly scaffolded. See `docs/HANDOFF.md` for the live agent handoff and `todos/` for next setup tasks.

## License

MIT. See `LICENSE`.
