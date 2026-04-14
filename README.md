# anyway, where was i

This site is a small Jekyll blog published at `https://pranavpipariya.github.io`.

## Writing posts with SageMath

GitHub Pages will not run SageMath for you during deploy, so the workflow here is:

1. Write the post in `_posts/`.
2. Put the SageMath code for that post in `sage/<slug>.sage`.
3. Run `./scripts/build_sage_posts.sh <slug>` locally.
4. Commit both the post and the generated files.

The generated output lives in `_includes/generated/` so posts can embed it with:

```liquid
{% raw %}{% include generated/<slug>.html %}{% endraw %}
```

## Notes

- If `sage` says it needs permission to reconfigure itself on macOS, open `SageMath-10-8.app` once from the GUI and rerun the script.
- If you want a local Jekyll preview, install the Bundler version from `Gemfile.lock` and run `bundle exec jekyll serve`.
