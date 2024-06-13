using System.Collections;
using System;
namespace Oregano.Automata;

public class Automaton
{
	private StringView source;
	private Cursor candidate;

	public FSM States;
	public Dictionary<StringView, int> NamedGroups;
	public List<Cursor> Cursors = new .() ~ DeleteContainerAndItems!(_);

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

	public Result<Match> Matches()
	{
		while(Cursors.Count > 0) { StepAll(); }
		if(candidate != null)
		{
			let m = Match(source, candidate.Groups, NamedGroups);
			candidate.Groups = null;
			delete candidate;
			return m;
		}
		return .Err;
	}

	private void StepAll()
	{
		var i = 0;
		while(i < Cursors.Count)
		{
			var c = Cursors[i];
     		if(!Step(c))
			{
				if(c.Current == States.End && (candidate == null || candidate.Position < c.Position))
				{
					if(candidate != null) delete candidate;
					c.Groups[0].End = c.Position;
					candidate = c;
				}
				else { delete c; }
				Cursors.RemoveAt(i);
			}
			else { i++; }
		}
	}

	private bool Step(Cursor c)
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
					Cursors.Add(nCur);
				}
				else { firstTransition = t; }
			}
		}

		if(firstTransition != null)
		{
			firstTransition.Apply(c);
			return true;
		}
		if(c.CanBacktrack)
		{
			c.PopState();
			return true;
		}
		return false;
	}
}