using System;
using System.Collections;
namespace Oregano;

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
		for(let s in visited) { delete s; }
	}
}

public class State
{
	public List<Transition> Transitions = new .() ~ DeleteContainerAndItems!(_);
}

public enum TransitionResult
{
	case Accepted(int count);
	case Rejected;
}

public class Cursor
{
	public StringView       String;
	public State            Current;
	public CompactList<int> Positions ~ _.Dispose();

	[Inline]
	public ref int Position => ref Positions[Positions.Count - 1];

	public (int Start, int End)[] Groups ~ delete _;

	public this(StringView s, State start, int position, int groupCount)
 	{
		 String   = s;
		 Current  = start;
		 Positions = .();
 		 Positions.Add(position);
		 Groups   = new .[groupCount];
	}
}

public abstract class Transition
{
	public State Target;
	public abstract TransitionResult Matches(Cursor c);
}

public class Epsilon : Transition
{
	public override TransitionResult Matches(Cursor c) => .Accepted(0);
}

public class CharacterMatch : Transition
{
	public char8 Character;
	public override TransitionResult Matches(Cursor c) => (c.String[c.Position] == Character) ? .Accepted(1) : .Rejected;
}

public class StringMatch : Transition
{
	public StringView String;
	public override TransitionResult Matches(Cursor c) => (c.String[c.Position...].StartsWith(String)) ? .Accepted(String.Length) : .Rejected;
}

public class GroupEntry : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c)
	{
		c.Groups[Group].Start = c.Position;
		return .Accepted(0);
	}
}

public class GroupExit : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c)
	{
		c.Groups[Group].End = c.Position;
		return .Accepted(0);
	}
}

public class Backreference : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c)
	{
		let substr  = c.String[c.Position...];
		let capture = c.String[(c.Groups[Group].Start)..<(c.Groups[Group].End)];

		return (substr.StartsWith(capture)) ? .Accepted(c.Groups[Group].End - c.Groups[Group].Start) : .Rejected;
	}
}

public class LookaheadEntry : Transition
{
	public override TransitionResult Matches(Cursor c)
	{
		c.Positions.Add(c.Position);
		return .Accepted(0);
	}
}

public class LookaheadExit : Transition
{
	public override TransitionResult Matches(Cursor c)
	{
		c.Positions.RemoveAt(c.Positions.Count - 1);
		return .Accepted(0);
	}
}