using System;
using System.Collections;
namespace Oregano.Compiler;

public class Parser
{
	public static char8[?] reserved = .('.','$','^','\\','(',')','*','+','[',']','|','\0');

	public StringView Regex;
	public int Position;
	public int GroupCount;
	public List<CharacterClass> Classes;

	public char8 Current => (Position < Regex.Length) ? Regex[Position] : '\0';

	public this(StringView regex)
	{
		Regex = regex;
		Position = 0;
		GroupCount = 0;
		Classes = new .();
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
		default:
			return child;
		}
	}

	public Result<IExpression> ParseExpression()
	{
		switch(Current)
		{
		case '.':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.Dot};
		case '$':
			Position++;
			return new AnchorExpr(){Type = .LineStart};
		case '^':
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
		let group = GroupCount;
		GroupCount++;
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
			Position++;
			return new BackreferenceExpr(){Group = Current - '0'};
		} 
		if(reserved.Contains(Current))
		{
			Position++;
			return new StringExpr(){String = Regex[Position...Position]};
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
		case 'b':
			Position++;
			return new AnchorExpr(){Type = .WordBoundary};
		case 'd':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.Digit};
		case 'D':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.NonDigit};
		case 'w':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.Word};
		case 'W':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.NonWord};
		case 's':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.Whitespace};
		case 'S':
			Position++;
			return new CharClassExpr(){CharClass = CharacterClass.NonWhitespace};
		default:
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

		let start = Try!(ParseChar());
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
				return '\t';
			case 'n':
				return '\n';
			case 'r':
				return '\r';
			case '\\':
				return '\\';
			case '-':
				return '-';
			case ']':
				return ']';
			default:
				return .Err;
			}
		}
		return Current;
	}

	public Result<IExpression> ParseString()
	{
		let start = Position;
		while(!reserved.Contains(Regex[Position])) Position++;

		if(start == Position) return .Err;
		return new StringExpr(){String = Regex[start..<Position]};
	}
}