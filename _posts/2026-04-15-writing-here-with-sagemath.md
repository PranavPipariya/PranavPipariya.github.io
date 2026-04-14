---
layout: post
title: "Writing here with SageMath"
date: 2026-04-15 04:00:00 +0530
categories: math tooling
---

I wanted this blog to be able to carry around little bits of actual computation instead of pretending everything was done by hand on a napkin.

The rule is simple: SageMath runs locally, writes static output into the repo, and Jekyll publishes that output like any other include. That keeps the site compatible with GitHub Pages while still letting me use the tools I actually want.

This block below comes from `sage/symbolic-scratchpad.sage`:

{% include generated/symbolic-scratchpad.html %}

If I update the Sage file, I just rerun:

```bash
./scripts/build_sage_posts.sh symbolic-scratchpad
```

That means future posts can use Sage for symbolic algebra, plots, number theory experiments, or whatever else I feel like poking at, without turning the deploy into a science project.
