# anyway, where was i

This is a small Jekyll blog published at `https://pranavpipariya.github.io`.

## Writing a new post

Fastest way:

```bash
./scripts/new_post.sh "your title"
```

That creates the markdown file for you.

To delete a post:

```bash
./scripts/new_post.sh --delete "your title"
```

or:

```bash
./scripts/new_post.sh --delete _posts/YYYY-MM-DD-your-title.md
```

Manual way:

Create a file in `_posts/` named like:

```text
YYYY-MM-DD-your-title.md
```

Use this shape:

```markdown
---
layout: post
title: "your title"
date: YYYY-MM-DD HH:MM:SS +0530
categories: whatever you want
---

write whatever you want
```

That is enough. Jekyll will automatically put it on the homepage and generate the post page.

## Local preview

```bash
bundle _2.6.9_ exec jekyll serve
```

Then open `http://127.0.0.1:4000`.
