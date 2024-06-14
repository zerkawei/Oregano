using System;
using System.Collections;
using Oregano.Automata;
namespace Oregano;

typealias MatchEvaluator = delegate void(Match match, String replaceStr);

public struct Match : IDisposable
{
	private Dictionary<StringView, int> namedCaptures;
	public StringView Source;
	public Range[] Captures;

	public this(StringView source, Range[] captures, Dictionary<StringView, int> names = null)
	{
		Source = source;
		Captures = captures;
		namedCaptures = names;
	}

	public StringView this[int i]           => Source[Captures[i]];
	public StringView this[StringView name] => this[namedCaptures[name]];

	public void Dispose() { delete Captures; }
}

public struct MatchEnumerator : IEnumerator<Match>
{
	Regex      Regex;
	StringView Source;
	int        CurPos;

	public this(Regex regex, StringView source)
	{
		CurPos = 0;
		Regex  = regex;
		Source = source;
	}

	public Result<Match> GetNext() mut
	{
		let automaton = scope Automaton(Regex, Source);

		Result<Match> res = ?;
		bool   foundMatch = false;

		while(!foundMatch && CurPos < Source.Length)
		{
			automaton.Cursors.Add(new .(Regex.States.Start, CurPos, Regex.GroupCount));

			if((res = automaton.Matches()) case .Ok(let m))
			{
				CurPos     = m.Captures[0].End;
				foundMatch = true;
			}
			else { CurPos++; }
		}
		return res;
	}
}

public struct ParallelMatchEnumerator : IEnumerator<Match>
{
	Regex      Regex;
	StringView Source;
	int        CurPos;

	public this(Regex regex, StringView source)
	{
		CurPos = 0;
		Regex  = regex;
		Source = source;
	}

	public Result<Match> GetNext() mut
	{
		let automaton = scope ParallelAutomaton(Regex, Source);

		Result<Match> res = ?;
		bool   foundMatch = false;

		while(!foundMatch && CurPos < Source.Length)
		{
			if((res = automaton.Matches(new .(Regex.States.Start, CurPos, Regex.GroupCount))) case .Ok(let m))
			{
				CurPos     = m.Captures[0].End;
				foundMatch = true;
			}
			else { CurPos++; }
		}
		return res;
	}
}