# Oregano
Oregano is a BFS RegEx engine for the [Beef programming language](https://github.com/beefytech/Beef).

## Usage

The `Regex.Compile` method is used to create regex objects.
```csharp
let regex = Regex.Compile("([\"'])\w+\\1").GetValueOrDefault();
```
The `IsMatch` method is used to test if a string matches a regex.
```csharp
if(regex.IsMatch("example string"))
{
    ...
}
```
The `Match` and `Matches` methods are used to get the match(es) in the specified string. (Note: the returned `Match` must be disposed)
```csharp
for(let match in regex.Matches("example string"))
{
    ...
    match.Dispose();
}
```
The `Replace` method is used to replace the matched string(s) using a constant or a function
```csharp
let str = scope String("example string")
regex.Replace(str, "replace string")
regex.Replace(str, scope (match, replaceStr) => { ... });
```

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
- `\1`|`\k<10>` Backreference via index
- `(?<name>expr)` Named capturing group
- `k<name>` Backreference via name
- `(?:expr)` Non capturing group
- `(?=expr)` Lookahead
- `(?!expr)` Negative lookahead
- `(?<=expr)` Lookbehind
- `(?<!expr)` Negative Lookbehind
