using System.Collections;
using System;
using Oregano.Compiler;
using Oregano.Automata;
namespace Oregano;

public class Regex
{
	private FSM compiledFsm ~ _.Dispose();
	private int groupCount;

	private List<Match> matches = new .() ~ DeleteContainerAndDisposeItems!(_);
	private List<CharacterClass> classes ~ if(_ != null) DeleteContainerAndItems!(_);

	private this() {}

	public static Regex Compile(StringView regex)
 	{
		let p = scope Parser(regex);
		if(p.ParseExpressions() case .Ok(let ast))
		{
			let res = new Regex();
			res.compiledFsm = ast.Compile();
			res.groupCount  = p.GroupCount;
			res.classes     = p.Classes;

			delete ast;
			return res;
		}
		return null;
	}

	public Result<Match> Matches(StringView s) => (scope Automaton(compiledFsm, new .(compiledFsm.Start, 0, groupCount), s)).Matches();
	public List<Match> MatchAll(StringView s)
	{
		matches.ClearAndDisposeItems();

		int startPos = 0;
		while(startPos < s.Length)
		{
			let automaton = scope Automaton(compiledFsm, new .(compiledFsm.Start, startPos, groupCount), s);
			if(automaton.Matches() case .Ok(let m))
			{
				matches.Add(m);
				startPos = m.Captures[0].End;
			}
			else { startPos++; }
		}

		return matches;
	}
}