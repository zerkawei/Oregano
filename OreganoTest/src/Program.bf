using Oregano;
using System;
namespace OreganoTest;

class Program
{
	public static void Main()
	{
		let regex = Regex.Compile("([\"'])a+\\0");

		for(let m in regex.MatchAll("\"a\" 'a'"))
		{
			for(let g in m)
			{
				Console.WriteLine(g);
			}
		}

		delete regex;

		Console.Read();
	}
}