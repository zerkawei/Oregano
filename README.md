# Oregano
Oregano is a BFS RegEx engine for the [Beef programming language](https://github.com/beefytech/Beef). The project is currently a work in progress and is not in a fully usable state.

## Supported regex features
### Character classes
- `.` Matches any character except new line
- `\d`|`\D` Matches any digit | non-digit
- `\w`|`\W` Matches any alphanumeric | non-alphanumeric
- `\s`|`\S` Matches any whitespace | non-whitespace
- `[xyz]` Matches 'x', 'y', or 'z'
- `[^xyz]` Matches any other than 'x', 'y', or 'z'
- `[a-z]` Matches any between 'a' and 'z' inclusive

### Quantifiers
- `*` Matches zero or more
- `+` Matches one or more
- `?` Matches zero or one
- `{m,n}` Matches at least m and at most n

### Assertions
- `^` Start of line assertion
- `$` End of line assertion
- `\b` Word boundary assertion
- `\A` Start of string assertion
- `\Z` End of string assertion

### Groups
- `(expr)` Capturing group
- `(?:expr)` Non capturing group
- `(?=expr)` Lookahead
- `(?!expr)` Negative lookahead
- `(?<=expr)` Lookbehind
- `(?<!expr)` Negative Lookbehind
- `\1` Backreference