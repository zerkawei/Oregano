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

	public static Result<Regex> Compile(StringView regexStr)
 	{
		let p = scope Parser(regexStr);
		let res = p.ParseExpressions();
		if(res case .Ok(let ast))
		{
			let regex         = new Regex();
			regex.States      = ast.Compile();
			regex.GroupCount  = p.GroupCount;
			regex.classes     = p.Classes;
			regex.NamedGroups = p.NamedGroups;

			delete ast;
			return regex;
		}

		delete p.Classes;
		delete p.NamedGroups;
		return .Err;
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