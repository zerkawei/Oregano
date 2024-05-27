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
	private Dictionary<StringView, int> namedGroups ~ if(_ != null) delete _;

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
			res.namedGroups = p.NamedGroups;

			delete ast;
			return res;
		}
		return null;
	}
 
	private Result<Match> MatchFrom(StringView s, ref int start)
	{
		let automaton = scope Automaton(compiledFsm, new .(compiledFsm.Start, start, groupCount), s);

		let res = automaton.Matches();
		if(res case .Ok(var m))
		{
			m.[Friend]namedCaptures = namedGroups;
			matches.Add(m);
			start = m.Captures[0].End;
		}
		else { start++; }

		return res;
	} 

	public Result<Match> Matches(StringView s)
	{
		matches.ClearAndDisposeItems();

		int startPos = 0;
		Result<Match> res = ?;
		while(startPos < s.Length && (res = MatchFrom(s, ref startPos)) case .Err) {}

		return res;
	}

	public List<Match> MatchAll(StringView s)
	{
		matches.ClearAndDisposeItems();

		int startPos = 0;
		while(startPos < s.Length)
		{
			let res = MatchFrom(s, ref startPos);
		}

		return matches;
	}
}