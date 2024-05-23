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
	public bool Reverse = true;
	public State Current;
	public CompactList<int> Positions = .() ~ _.Dispose();
	public (int Start, int End)[] Groups    ~ delete _;

	[Inline]
	public ref int Position => ref Positions[Positions.Count - 1];

	public this(State start, int position, int groupCount)
 	{
		Current = start;
		Groups  = new .[groupCount];
		Positions.Add(position);
	}

	public this(Cursor parent, State target, int position)
	{
		Reverse = parent.Reverse;
		Current = target;
		Groups  = new .[parent.Groups.Count];

		parent.Groups.CopyTo(Groups);
		for(let pos in parent.Positions)
		{
			Positions.Add(pos);
		}

		Position = position;
	}

	public bool MatchesString(StringView source, StringView match) => Reverse ? source[...Position].EndsWith(match) : source[Position...].StartsWith(match);
}

public abstract class Transition
{
	public State Target;
	public abstract TransitionResult Matches(Cursor c, StringView s);
}

public class Epsilon : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s) => .Accepted(0);
}

public class CharacterMatch : Transition
{
	public char8 Character;
	public override TransitionResult Matches(Cursor c, StringView s) => (s[c.Position] == Character) ? .Accepted(1) : .Rejected;
}

public class StringMatch : Transition
{
	public StringView String;
	public override TransitionResult Matches(Cursor c, StringView s) => (c.MatchesString(s, String)) ? .Accepted(String.Length) : .Rejected;
}

public class GroupEntry : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Groups[Group].Start = c.Position;
		return .Accepted(0);
	}
}

public class GroupExit : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Groups[Group].End = c.Position;
		return .Accepted(0);
	}
}

public class Backreference : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		let capture = s[(c.Groups[Group].Start)..<(c.Groups[Group].End)];
		return (c.MatchesString(s, capture)) ? .Accepted(c.Groups[Group].End - c.Groups[Group].Start) : .Rejected;
	}
}

public class LookaheadEntry : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Positions.Add(c.Position);
		return .Accepted(0);
	}
}

public class LookaheadExit : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Positions.RemoveAt(c.Positions.Count - 1);
		return .Accepted(0);
	}
}

public class LookbehindEntry : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Reverse = true;
		c.Positions.Add(c.Position);
		return .Accepted(0);
	}
}

public class LookbehindExit : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Reverse = false;
		c.Positions.RemoveAt(c.Positions.Count - 1);
		return .Accepted(0);
	}
}

public class ClassMatch : Transition
{
	public CharacterClass CharClass;

	public override TransitionResult Matches(Cursor c, StringView s)
	{
		return CharClass.Contains(s[c.Position]) ? .Accepted(1) : .Rejected;
	}
}