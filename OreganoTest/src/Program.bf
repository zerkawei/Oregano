using Oregano;
using System;
namespace OreganoTest;

class Program
{
	public static void Main()
	{
		RegexMatch("([\"'])a+\\1", "\"a\" 'aaaa'");
		RegexMatch("<(?<tag>[^>]+)>(?<inner>[^<]*)</\\k<tag>>", "<div>Test</div>");
		RegexMatch("(?<![$€])\\d+","Buy 99 for $2");

		Console.Read();
	}

	public static void RegexMatch(StringView reg, StringView str)
	{
		if(Regex.Compile(reg) case .Ok(let regex))
		{
			for(let m in regex.Matches(str))
			{
				Console.WriteLine("Match :");
				for(let i < m.Captures.Count)
				{
					Console.WriteLine(scope $"    Group {i}: {m[i]}");
				}
				m.Dispose();
			}
			delete regex;
		}
	}
}