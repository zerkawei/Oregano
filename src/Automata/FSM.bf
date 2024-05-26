using System;
using System.Collections;
using internal Oregano.Automata;
namespace Oregano.Automata;

public struct FSM : IDisposable
{
	public State Start;
	public State End;

	public this(State start, State end)
	{
		Start = start;
		End   = end;
	}

	public void Dispose()
	{
		HashSet<State> visited = scope .();
		void Visit(State s)
		{
			visited.Add(s);
			for(let t in s.Transitions)
			{
				if(!visited.Contains(t.Target))
				{
					Visit(t.Target);
				}
			}
		}
		Visit(Start);
		visited.ClearAndDelete();
	}

	public void Reverse() mut
	{
		HashSet<State> visited = scope .();
		List<(State s, Transition t)> pairs = scope .();
		void Visit(State s)
		{
			visited.Add(s);
			for(let t in s.Transitions)
			{
				pairs.Add((s,t));
				if(!visited.Contains(t.Target))
				{
					Visit(t.Target);
				}
			}
			s.Transitions.Clear();
		}
		Visit(Start);

		for(let pair in pairs)
		{
			pair.t.Target.Transitions.Add(pair.t);
			pair.t.Target = pair.s;
		}

		let temp = Start;
		Start = End;
		End = temp;
	}
}

public class State
{
	public List<Transition> Transitions = new .() ~ DeleteContainerAndItems!(_);
}
