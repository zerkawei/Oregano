using System;
using System.Collections;
namespace Oregano.Compiler;

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
	public struct SavedPos
	{
		[Bitfield<uint>(.Public, .Bits(63), "Position")]
		[Bitfield<bool>(.Public, .Bits(1), "Reverse")]
		private int data;

		public this(int pos, bool rev)
		{
			data = ?;
			Position = (uint)pos;
			Reverse = rev;
		}
	}

	public State Current;
	public CompactList<SavedPos> Positions = .() ~ _.Dispose();
	public (int Start, int End)[] Groups    ~ delete _;

	public int Position
	{
		get => (int)Positions[Positions.Count - 1].Position;
		set => Positions[Positions.Count - 1].Position = (uint)value;
	}
	public bool Reverse => Positions[Positions.Count - 1].Reverse;

	public this(State start, int position, int groupCount)
 	{
		Current = start;
		Groups  = new .[groupCount];
		Positions.Add(.(position, false));
	}

	public this(Cursor parent, State target, int position)
	{
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
	public mixin BoundaryCheck(StringView s)
	{
		if(Position >= s.Length || Position < 0) return TransitionResult.Rejected;
	}
}

public abstract class Transition
{
	public State Target;
	public abstract TransitionResult Matches(Cursor c, StringView s);
}

// EPSILONS

public class Epsilon : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s) => .Accepted(0);
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

public class LookaheadEntry : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.Positions.Add(.(c.Position, false));
		return .Accepted(0);
	}
}

public class LookaroundExit : Transition
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
		c.Positions.Add(.(c.Position, true));
		return .Accepted(0);
	}
}

// CONDITIONAL EPSILONS

public class LineStart : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		return (c.Position == 0 || s[c.Position-1] == '\n') ? .Accepted(0) : .Rejected;
	}
}

public class LineEnd : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		return (c.Position == s.Length || s[c.Position] == '\n') ? .Accepted(0) : .Rejected;
	}
}

public class StringStart : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		return (c.Position == 0) ? .Accepted(0) : .Rejected;
	}
}

public class StringEnd : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		return (c.Position == s.Length) ? .Accepted(0) : .Rejected;
	}
}

public class WordBoundary : Transition
{
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		return (((c.Position == 0 || s[c.Position-1].IsWhiteSpace) && CharacterClass.Word.Contains(s[c.Position])) || ((c.Position == s.Length || s[c.Position].IsWhiteSpace) && CharacterClass.Word.Contains(s[c.Position-1]))) ?
			.Accepted(0) : .Rejected;
	}
}

// MATCHERS

public class CharacterMatch : Transition
{
	public char8 Character;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.BoundaryCheck!(s);
		return (s[c.Position] == Character) ? .Accepted(1) : .Rejected;
	}
}

public class StringMatch : Transition
{
	public StringView String;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.BoundaryCheck!(s);
		return (c.MatchesString(s, String)) ? .Accepted(String.Length) : .Rejected;
	}
}

public class Backreference : Transition
{
	public int Group;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.BoundaryCheck!(s);
		let capture = s[(c.Groups[Group].Start)..<(c.Groups[Group].End)];
		return (c.MatchesString(s, capture)) ? .Accepted(c.Groups[Group].End - c.Groups[Group].Start) : .Rejected;
	}
}

public class ClassMatch : Transition
{
	public CharacterClass CharClass;
	public override TransitionResult Matches(Cursor c, StringView s)
	{
		c.BoundaryCheck!(s);
		return CharClass.Contains(s[c.Position]) ? .Accepted(1) : .Rejected;
	}
}

