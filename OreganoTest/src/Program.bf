using Oregano;
using System;
namespace OreganoTest;

class Program
{
	public static void Main()
	{
		RegexMatch("([\"'])a+\\1", "\"a\" 'aaaa'");
		RegexMatch("<[^>]+>", "<div>Test</div>");
		RegexMatch("(?<![$€])\\d+","Buy 99 for $2");

		Console.Read();
	}

	public static void RegexMatch(StringView reg, StringView str)
	{
		let regex = Regex.Compile(reg);

		for(let m in regex.MatchAll(str))
		{
			Console.WriteLine("Match :");
			for(let i < m.Captures.Count)
			{
				Console.WriteLine(scope $"    Group {i}: {m[i]}");
			}
		}

		delete regex;
	}
}