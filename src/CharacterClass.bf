using System.Collections;
namespace Oregano;

public class CharacterClass
{
	public static Self Dot           = new .(new .('\n','\r'), new .(), true) ~ delete _;
	public static Self Digit         = new .(new .(), new .(.('0','9'))) ~ delete _;
 	public static Self NonDigit      = new .(new .(), new .(.('0','9')), true) ~ delete _;
	public static Self Word          = new .(new .('_'), new .(.('a','z'), .('A','Z'), .('0','9'))) ~ delete _;
	public static Self NonWord       = new .(new .('_'), new .(.('a','z'), .('A','Z'), .('0','9')), true) ~ delete _;
	public static Self Whitespace    = new .(new .(' ', '\f', '\n', '\r', '\t', '\v', '\xa0'), new .()) ~ delete _;
	public static Self NonWhitespace = new .(new .(' ', '\f', '\n', '\r', '\t', '\v', '\xa0'), new .(), true) ~ delete _;

	public static Dictionary<char8, Self> Shorthands = new .() ~ delete _;

	public bool Negated;
	public char8[] Characters ~ delete _;
	public CharacterRange[] Ranges ~ delete _;

	public static this()
	{
		Shorthands.Add('d', Digit);
		Shorthands.Add('D', NonDigit);
		Shorthands.Add('w', Word);
		Shorthands.Add('W', NonWord);
		Shorthands.Add('s', Whitespace);
		Shorthands.Add('S', NonWhitespace);
	}

	public this(char8[] chars, CharacterRange[] ranges, bool negated = false)
	{
		Negated    = negated;
		Characters = chars;
		Ranges     = ranges;
	}

	public bool Contains(char8 c)
	{
		if(Characters.Contains(c)) return !Negated;
		for(let r in Ranges)
		{
			if(r.Start <= c && c <= r.End) return !Negated;
		}
		return Negated;
	}	
}

public struct CharacterRange
{
	public char8 Start;
	public char8 End;

	public this(char8 start, char8 end)
	{
		Start = start;
		End = end;
	}
}