using System;
using System.Collections;
namespace Oregano.Compiler;

public class Parser
{
	static char8[?] reserved = .('.','$','^','\\','(',')','*','+','[',']','|','{','}','?','\0');
	StringView Regex;
	int Position;


	public List<CharacterClass> Classes;
	public Dictionary<StringView, int> NamedGroups;
	public int GroupCount;

	char8 Current => (Position < Regex.Length) ? Regex[Position] : '\0';

	public this(StringView regex)
	{
		Regex = regex;
		Position = 0;
		GroupCount = 0;
		Classes = new .();
		NamedGroups = new .();
	}

	public Result<IExpression> ParseExpressions()
	{
		let left = Try!(ParseQuantifiers());
		switch(Current)
		{
		case ')': fallthrough;
		case '\0':
			return left;
		case '|':
			Position++;
			if(ParseExpressions() case .Ok(let right)) return new OrExpr(){Left = left, Right = right};
			delete left;
			return .Err;
		default:
			if(ParseExpressions() case .Ok(let right)) return new ConcatExpr(){Left = left, Right = right};
			delete left;
			return .Err;
		}
	}

	public Result<IExpression> ParseQuantifiers()
	{
		let child = Try!(ParseExpression());
		switch(Current)
		{
		case '*':
			Position++;
			return new StarExpr(){Child = child};
		case '+':
			Position++;
			return new PlusExpr(){Child = child};
		case '?':
			Position++;
			return new OptionalExpr(){Child = child};
		case '{':
			Position++;
			return ParseCardinality(child);
		default:
			return child;
		}
	}

	public Result<IExpression> ParseCardinality(IExpression child)
	{
		let start = ParseInt();
		if(Current == '}')
		{
			Position++;
			return new CardinalityExpr(){Child = child, Cardinality = .(start, start)};
		}
		else if(Current != ',') { return .Err; }
		Position++;

		let end = ParseInt();

		if(Current != '}') return .Err;
		Position++;

		return new CardinalityExpr(){Child = child, Cardinality = .(start, (end == 0) ? int.MaxValue : end)};
	}

	public int ParseInt()
	{
		var value = 0;
		while(Current.IsDigit)
		{
			value = (10 * value) + (Current - '0');
			Position++;
		}
		return value;
	}

	public Result<IExpression> ParseExpression()
	{
		switch(Current)
		{
		case '.':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.Dot};
		case '^':
			Position++;
			return new AnchorExpr(){Type = .LineStart};
		case '$':
			Position++;
			return new AnchorExpr(){Type = .LineEnd};
		case '(':
			Position++;
			return ParseGroup();
		case '\\':
			Position++;
			return ParseEscape();
		case '[':
			Position++;
			return ParseClass();
		default:
			return ParseString();
		}
	}

	public Result<IExpression> ParseGroup()
	{
		if(Current == '?')
		{
			Position++;
		    switch(Current)
			{
			case ':':
				Position++;
				return ParseNonCapturingGroup();
			case '<':
				Position++;
				return Current.IsLetter ? ParseNamedGroup() : ParseLookaround(true);
			default:
				return ParseLookaround();
			}
		}
		return ParseCapturingGroup(++GroupCount);
	}

	public Result<IExpression> ParseNonCapturingGroup()
	{
		let inner = Try!(ParseExpressions());
		if(Current != ')')
		{
			delete inner;
			return .Err;
		}
		Position++;
		return inner;
	}

	public Result<IExpression> ParseLookaround(bool behind = false)
	{
		bool negative = ?;
		switch(Current)
		{
		case '=':
			negative = false;
		case '!':
			negative = true;
		default:
			return .Err;
		}
		Position++;

		let inner = Try!(ParseExpressions());
		if(Current != ')')
		{
			delete inner;
			return .Err;
		}
		Position++;
		return new LookaroundExpr(){Child = inner, Behind = behind, Negative = negative};
	}

	public Result<IExpression> ParseNamedGroup()
	{
		let name = ParseName();

		if(Current != '>') return .Err;
		Position++;

		int group = ?;
		if(NamedGroups.ContainsKey(name))
		{
			group = NamedGroups[name];
		}
		else
		{
			group = ++GroupCount;
			NamedGroups.Add(name, group);
		}

		return ParseCapturingGroup(group);
	}

	public Result<IExpression> ParseCapturingGroup(int group)
	{
		let inner = Try!(ParseExpressions());
		if(Current != ')')
		{
			delete inner;
			return .Err;
		}
		Position++;
		return new GroupExpr(){Group = group, Child = inner};
	}

	public Result<IExpression> ParseEscape()
	{
		if(Current.IsDigit)
		{
			let group = int(Current - '0');
			Position++;
			return new BackreferenceExpr(){Group = group};
		} 
		if(reserved.Contains(Current))
		{
			return new CharExpr(){Char = Regex[Position++]};
		}
		switch(Current)
		{
		case '\0':
			return .Err;
		case 'A':
			Position++;
			return new AnchorExpr(){Type = .StringStart};
		case 'Z':
			Position++;
			return new AnchorExpr(){Type = .StringEnd};
		case 'k':
			Position++;
			if(Current != '<') return .Err;
			Position++;
			let name = ParseName();
			if(Current != '>') return .Err;
			Position++;
			return (NamedGroups.TryGetValue(name, let group)) ? new BackreferenceExpr(){Group = group} : .Err;
		default:
			if(CharacterClass.Shorthands.TryGetValue(Current, let charClass))
			{
				Position++;
				return new CharClassExpr(){CharClass = charClass};
			}
			return .Err;
		}
	}

	public Result<IExpression> ParseClass()
	{
		let chars   = scope List<char8>();
		let ranges  = scope List<CharacterRange>();
		var negated = false; 
		
		if(Current == '^')
		{
			Position++;
			negated = true;
		}

		while(Try!(ParseRange(chars, ranges))) {}
		Position++;

		let charClass = new CharacterClass(new char8[chars.Count], new CharacterRange[ranges.Count], negated);
		chars.CopyTo(charClass.Characters);
		ranges.CopyTo(charClass.Ranges);

		Classes.Add(charClass);
		return new CharClassExpr(){CharClass = charClass};
	}

	public Result<bool> ParseRange(List<char8> chars, List<CharacterRange> ranges)
 	{
		if(Current == ']') return false;

		char8 start = ?;
		if(Current == '\\')
		{
			Position++;
			if(CharacterClass.Shorthands.TryGetValue(Current, let charClass))
			{
				Position++;
				for(let c in charClass.Characters)
				{
					chars.Add(c);
				}
				for(let r in charClass.Ranges)
				{
					ranges.Add(r);
				}
				return true;
			}
			switch(Current)
			{
			case 't':
				start = '\t';
			case 'n':
				start = '\n';
			case 'r':
				start = '\r';
			case '\\':
				start = '\\';
			case '-':
				start = '-';
			case ']':
				start = ']';
			default:
				return .Err;
			}
		}
		else { start = Current; }

		Position++;
		if(Current == '-')
		{
			let end = Try!(ParseChar());
			ranges.Add(.(start, end));
			return true;
		}
		chars.Add(start);
		return true;
	}

	public Result<char8> ParseChar()
	{
		if(Current == '\\')
		{
			Position++;
			switch(Current)
			{
			case 't':
				Position++;
				return '\t';
			case 'n':
				Position++;
				return '\n';
			case 'r':
				Position++;
				return '\r';
			case '\\':
				Position++;
				return '\\';
			case '-':
				Position++;
				return '-';
			case ']':
				Position++;
				return ']';
			default:
				return .Err;
			}
		}
		return Current;
	}

	public StringView ParseName()
	{
		let pos = Position;
		while(CharacterClass.Word.Contains(Current)) { Position++; }

		return Regex[pos...Position];
	}

	public Result<IExpression> ParseString()
	{
		let start = Position;
		while(!reserved.Contains(Current)) Position++;

		if(start == Position) return .Err;
		return new StringExpr(){String = Regex[start..<Position]};
	}
}