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

	public bool IsMatchParallel(StringView s)
	{
		if(MatchParallel(s) case .Ok(let m))
		{
			m.Dispose();
			return true;
		}
		return false;
	}
	public Result<Match>           MatchParallel(StringView s)   => ParallelMatchEnumerator(this, s).GetNext();
	public ParallelMatchEnumerator MatchesParallel(StringView s) => ParallelMatchEnumerator(this, s);


	public void Replace(String s, StringView replaceStr, int count = int.MaxValue)
	{
		var enumerator = MatchEnumerator(this, s);
		var i = 0;

		while(i++ < count && enumerator.GetNext() case .Ok(let match))
		{
			let matchStr = match[0];
			let start    = match.Captures[0].Start;

			if(matchStr != replaceStr)
			{
				s.Remove(start, matchStr.Length);
				s.Insert(start, replaceStr);
				enumerator.[Friend]CurPos = start + replaceStr.Length;
			}
			match.Dispose();
		}
	}

	public void Replace(String s, MatchEvaluator evaluator, int count = int.MaxValue)
	{
		var enumerator = MatchEnumerator(this, s);
		var i = 0;

		while(i++ < count && enumerator.GetNext() case .Ok(let match))
		{
			let matchStr   = match[0];
			let start      = match.Captures[0].Start;
			let replaceStr = evaluator(match, .. scope .());

			if(matchStr != replaceStr)
			{
				s.Remove(start, matchStr.Length);
				s.Insert(start, replaceStr);
				enumerator.[Friend]CurPos = start + replaceStr.Length;
			}
			match.Dispose();
		}
	}
}