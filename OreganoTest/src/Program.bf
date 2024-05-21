using Oregano;
using System;
namespace OreganoTest;

class Program
{
	public static void Main()
	{
		let ast = scope ConcatExpr()
		{
			Left = scope GroupExpr()
			{
				Group = 0,
				Child = scope OrExpr()
				{
					Left  = scope StringExpr(){ String = "\"" },
					Right = scope StringExpr(){ String = "'"}
				}
			},
			Right = scope ConcatExpr()
			{
				Left  = scope StringExpr(){ String = "a" },
				Right = scope BackreferenceExpr(){ Group = 0 }
			}
		};

		let regex = scope Regex();
		regex.[Friend]compiledFsm = ast.Compile();
		regex.[Friend]groupCount  = 1;

		for(let m in regex.MatchAll("\"a\" 'a'"))
		{
			for(let g in m)
			{
				Console.WriteLine(g);
			}
		}

		Console.Read();
	}
}