# Serializing a line drops one real space after a tab (as_text / as_ansi / get-text)

**kitty 0.48.2** (source references below are from the 0.48.1 tag), Linux/X11.

When a line contains a tab and the cell *directly after the tab's covered
range* holds a real space, that space is lost when the line is serialized
back to text. Any consumer that re-expands the emitted `\t` (less, `kitty @
get-text` users, kittens) renders the following text one column further left
than the live screen shows it.

User-visible: `ls`' columnar output separates columns with tabs plus literal
spaces — in the scrollback pager (`show_scrollback`) the columns are shifted
by one per tab boundary compared to the terminal.

## Reproducer

```
kitty +runpy "
from kitty.fast_data_types import Screen
class CB:
    def __getattr__(self, n): return lambda *a, **k: None
cb = CB()
s = Screen(cb, 5, 20, 20, 10, 20, 0, cb)
data = memoryview(b'ab\t X\r\n')     # tab (stops at col 8), one REAL space, X
while data:
    dest = s.test_create_write_buffer()
    n = s.test_commit_write_buffer(data, dest)
    data = data[n:]
    s.test_parse_written_data(None)
line = s.line(0)
print('cells    :', [line[i] for i in range(11)])
print('as_ansi():', repr(line.as_ansi()))
print('str(line):', repr(str(line)))
"
```

Output:

```
cells    : ['a', 'b', '\t\x06', ' ', ' ', ' ', ' ', ' ', ' ', 'X', '\x00']
as_ansi(): 'ab\tX'
str(line): 'ab\tX'
```

The grid is correct: the tab covers columns 2–7 (span 6 stored in the cell),
the real space sits at column 8, `X` at column 9. The serialized text lost
the space — re-expanding its `\t` puts `X` at column 8.

Same effect interactively: `printf 'ab\t X\n'`, then compare the screen with
`kitty @ get-text`.

## Cause

`screen_tab` (kitty/screen.c:2085) stores `diff = found - cursor->x` in the
tab cell — the number of columns the tab covers **including the tab cell
itself**. So only `diff - 1` spacer cells follow the tab.

The serializer's skip loop, however, skips up to `diff` following cells as
long as they are spaces (kitty/line.c:604, same pattern at line.c:459 and
line.c:980):

```c
while (num_cells_to_skip_for_tab && s->pos + 1 < s->limit && cell_is_char(next, ' ')) {
    num_cells_to_skip_for_tab--; s->pos++; next++;
}
```

With `diff - 1` spacers present, the loop still has budget for one more
cell; an adjacent real space is consumed and never emitted. The `cell_is_char`
guard only saves the case where non-space text follows the tab range.

## Suggested fix

Skip at most `span - 1` cells (the spacers written by `screen_tab`), e.g.
initialize the counter with `num_cells_to_skip_for_tab - 1`, in all three
loops.
