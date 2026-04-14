from pathlib import Path

root = Path(__file__).resolve().parent.parent
output_dir = root / "_includes" / "generated"
output_dir.mkdir(parents=True, exist_ok=True)
output_file = output_dir / "symbolic-scratchpad.html"

R.<x> = QQ[]
matrix_value = matrix([[1, 2, 3], [0, 1, 4], [5, 6, 0]])
polynomial = x^4 - 1
factored = factor(polynomial)
determinant = matrix_value.det()
integral_value = integral(sin(x)^5, x)

html = f"""<section class="sage-output">
  <h2>SageMath output</h2>
  <p>This block is generated locally from <code>sage/symbolic-scratchpad.sage</code>.</p>
  <pre><code>factor(x^4 - 1) = {factored}
det([[1, 2, 3], [0, 1, 4], [5, 6, 0]]) = {determinant}
integral(sin(x)^5, x) = {integral_value}</code></pre>
</section>
"""

output_file.write_text(html)
print(f"Wrote {output_file.relative_to(root)}")
