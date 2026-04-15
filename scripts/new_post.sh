#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/new_post.sh "post title"
  ./scripts/new_post.sh --delete "post title"
  ./scripts/new_post.sh --delete _posts/YYYY-MM-DD-post-title.md
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

delete_mode=false
if [[ "${1:-}" == "--delete" ]]; then
  delete_mode=true
  shift
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

title="$*"

if [[ "$delete_mode" == true ]]; then
  target="$title"

  if [[ -f "$target" ]]; then
    rm -f "$target"
    echo "deleted $target"
    exit 0
  fi

  slug="$(slugify "$title")"
  matches=( _posts/*-"$slug".md )

  if [[ ${#matches[@]} -eq 0 || "${matches[0]}" == "_posts/*-$slug.md" ]]; then
    echo "No post found for title: $title" >&2
    exit 1
  fi

  if [[ ${#matches[@]} -gt 1 ]]; then
    echo "Multiple posts matched. Delete one explicitly:" >&2
    printf '%s\n' "${matches[@]}" >&2
    exit 1
  fi

  rm -f "${matches[0]}"
  echo "deleted ${matches[0]}"
  exit 0
fi

date_stamp="$(date +%F)"
time_stamp="$(date '+%Y-%m-%d %H:%M:%S %z')"
slug="$(slugify "$title")"

if [[ -z "$slug" ]]; then
  echo "Could not create a slug from title: $title" >&2
  exit 1
fi

post_path="_posts/${date_stamp}-${slug}.md"

if [[ -e "$post_path" ]]; then
  echo "Post already exists: $post_path" >&2
  exit 1
fi

mkdir -p "_posts"

cat > "$post_path" <<EOF
---
layout: post
title: "$title"
date: $time_stamp
categories: notes
---

start writing
EOF

echo "$post_path"
