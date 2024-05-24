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

public class Cursor
{
	public struct SavedPos
	{
		[Bitfield<uint>(.Public, .Bits(62), "Position")]
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
	public CompactList<int> RepeatCount = .() ~ _.Dispose();
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

	public this(Cursor parent)
	{
		Current = parent.Current;
		Groups  = new .[parent.Groups.Count];

		parent.Groups.CopyTo(Groups);
		for(let pos in parent.Positions)
		{
			Positions.Add(pos);
		}

		for(let i in parent.RepeatCount)
		{
			RepeatCount.Add(i);
		}
	}

	public bool MatchesString(StringView source, StringView match) => Reverse ? source[...Position].EndsWith(match) : source[Position...].StartsWith(match);
	public bool Inbounds(StringView s) => (Position < s.Length && Position >= 0);
}

public abstract class Transition
{
	public State Target;
	public abstract int Step { get; }
	public abstract bool Matches(Cursor c, StringView s);
	public virtual void Apply(Cursor c)
	{
		c.Position += c.Reverse ? -Step : Step;
		c.Current = Target;
	}
}

// EPSILONS

public class Epsilon : Transition
{
	public override int Step => 0;
	public override bool Matches(Cursor c, StringView s) => true;
}

public class GroupEntry : Epsilon
{
	public int Group;
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.Groups[Group].Start = c.Position;
	}
}

public class GroupExit : Epsilon
{
	public int Group;
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.Groups[Group].End = c.Position;
	}
}

public class LookaheadEntry : Epsilon
{
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.Positions.Add(.(c.Position, false));
	}
}

public class LookaroundExit : Epsilon
{
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.Positions.RemoveAt(c.Positions.Count - 1);
	}
}

public class LookbehindEntry : Epsilon
{
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.Positions.Add(.(c.Position, true));
	}
}

public class RepeatEntry : Epsilon
{
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.RepeatCount.Add(1);
	}
}

// CONDITIONAL EPSILONS

public class LineStart : Epsilon
{
	public override bool Matches(Cursor c, StringView s) => (c.Position == 0 || s[c.Position-1] == '\n');
}

public class LineEnd : Epsilon
{
	public override bool Matches(Cursor c, StringView s) => (c.Position == s.Length || s[c.Position] == '\n');
}

public class StringStart : Epsilon
{
	public override bool Matches(Cursor c, StringView s) => (c.Position == 0);
}

public class StringEnd : Epsilon
{
	public override bool Matches(Cursor c, StringView s) => (c.Position == s.Length);
}

public class WordBoundary : Epsilon
{
	public override bool Matches(Cursor c, StringView s)
		=> (((c.Position == 0 || s[c.Position-1].IsWhiteSpace) && CharacterClass.Word.Contains(s[c.Position])) || ((c.Position == s.Length || s[c.Position].IsWhiteSpace) && CharacterClass.Word.Contains(s[c.Position-1])));
}

public class MinimumCardinality : Epsilon
{
	public int lowerBound;
	public override bool Matches(Cursor c, StringView s) => (c.RepeatCount[c.RepeatCount.Count - 1] >= lowerBound);
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.RepeatCount.RemoveAt(c.RepeatCount.Count - 1);
	}
}

public class MaximumCardinality : Epsilon
{
	public int upperBound;
	public override bool Matches(Cursor c, StringView s) => (c.RepeatCount[c.RepeatCount.Count - 1] <= upperBound);
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.RepeatCount[c.RepeatCount.Count - 1]++;
	}
}

// MATCHERS

public class CharacterMatch : Transition
{
	public char8 Character;
	public override int Step => 1;
	public override bool Matches(Cursor c, StringView s) => c.Inbounds(s) && (s[c.Position] == Character);
}

public class StringMatch : Transition
{
	public StringView String;
	public override int Step => String.Length;
	public override bool Matches(Cursor c, StringView s) => c.Inbounds(s) && (c.MatchesString(s, String));
}

public class Backreference : Transition
{
	public int Group;
	public override int Step => 0;
	public override bool Matches(Cursor c, StringView s) => c.Inbounds(s) && (c.MatchesString(s, s[(c.Groups[Group].Start)..<(c.Groups[Group].End)]));
	public override void Apply(Cursor c)
	{
		let step = c.Groups[Group].End - c.Groups[Group].Start;
		c.Position += c.Reverse ? -step : step;
		c.Current = Target;
	}
}

public class ClassMatch : Transition
{
	public CharacterClass CharClass;
	public override int Step => 1;
	public override bool Matches(Cursor c, StringView s) => c.Inbounds(s) && CharClass.Contains(s[c.Position]);
}

