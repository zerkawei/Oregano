using System;
using System.Collections;
using System.Threading;
namespace Oregano.Automata;

public class ParallelAutomaton
{
	private StringView source;
	private Cursor candidate;
	private Monitor candidateMon = new .() ~ delete _;

	public FSM States;
	public Dictionary<StringView, int> NamedGroups;

	public this(Regex regex, StringView source)
	{
		this.States = regex.States;
		this.NamedGroups = regex.NamedGroups;
		this.source = source;
	}

	public this(FSM states, StringView source)
	{
		this.States = states;
		this.source = source;
	}

	public Result<Match> Matches(Cursor c)
	{
		RunCursor(c);
		if(candidate != null)
		{
			let m = Match(source, candidate.Groups, NamedGroups);
			candidate.Groups = null;
			delete candidate;
			return m;
		}
		return .Err;
	}

	private void RunCursor(Cursor c)
	{
		var hasTransitioned = true;
		while(hasTransitioned)
		{
			Transition firstTransition = null;
			for(let t in c.Current.Transitions)
			{
			    if(t.Matches(c, source))
				{
					if(firstTransition != null)
					{
						let nCur = new Cursor(c);
						t.Apply(nCur);

						let thread = scope:: Thread(new (x) => RunCursor((.)x));
						thread.Start(nCur, false);
						defer:: thread.Join();
					}
					else { firstTransition = t; }
				}
			}

			if(firstTransition != null)
			{
				firstTransition.Apply(c);
			}
			else if(c.CanBacktrack && c.Current != States.End)
			{
				c.PopState();
			}
			else { hasTransitioned = false; }
		}

		if(c.Current == States.End)
		{
			candidateMon.Enter();
			if(candidate == null || candidate.Position < c.Position)
			{
				if(candidate != null) delete candidate;
				c.Groups[0].End = c.Position;
				candidate = c;
			}
			else { delete c; }	
			candidateMon.Exit();
		}
		else { delete c; }
	}
}