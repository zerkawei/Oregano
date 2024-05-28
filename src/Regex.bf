using System.Collections;
using System;
using Oregano.Compiler;
using Oregano.Automata;
namespace Oregano;

public class Regex
{
	public FSM States ~ _.Dispose();
	public int GroupCount;
	public Dictionary<StringView, int> NamedGroups ~ if(_ != null) delete _;

	private List<CharacterClass> classes ~ if(_ != null) DeleteContainerAndItems!(_);

	private this() {}

	public static Regex Compile(StringView regex)
 	{
		let p = scope Parser(regex);
		if(p.ParseExpressions() case .Ok(let ast))
		{
			let res = new Regex();
			res.States = ast.Compile();
			res.GroupCount  = p.GroupCount;
			res.classes     = p.Classes;
			res.NamedGroups = p.NamedGroups;

			delete ast;
			return res;
		}
		return null;
	}

	public bool IsMatch(StringView s)
	{
		if(Match(s) case .Ok(let m))
		{
			m.Dispose();
			return true;
		}
		return false;
	}
	public Result<Match>   Match(StringView s)   => MatchEnumerator(this, s).GetNext();
	public MatchEnumerator Matches(StringView s) => MatchEnumerator(this, s);
}