using System.Collections;
using System;
namespace Oregano.Automata;

public class Automaton
{
	private FSM states;
	private StringView source;
	private Cursor candidate;
	private List<Cursor> cursors = new .() ~ DeleteContainerAndItems!(_);

	public this(FSM states, Cursor cursor, StringView source)
	{
		this.states = states;
		this.source = source;
		cursors.Add(cursor);
	}

	public Result<Match> Matches()
	{
		while(cursors.Count > 0) { StepAll(); }
		if(candidate != null)
		{
			let m = Match(source, candidate.Groups);
			candidate.Groups = null;
			delete candidate;
			return m;
		}
		return .Err;
	}

	private void StepAll()
	{
		var i = 0;
		while(i < cursors.Count)
		{
			var c = cursors[i];
     		if(!Step(c))
			{
				if(c.Current == states.End && (candidate == null || candidate.Position < c.Position))
				{
					if(candidate != null) delete candidate;
					c.Groups[0].End = c.Position;
					candidate = c;
				}
				else { delete c; }
				cursors.RemoveAt(i);
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
					cursors.Add(nCur);
				}
				else { firstTransition = t; }
			}
		}

		firstTransition?.Apply(c);
		return firstTransition != null;
	}
}