using System;
namespace Oregano.Automata;

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

public class LookaroundEntry : Epsilon
{
	public bool Reverse;
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.PushState(.(Reverse ? c.Position - 1 : c.Position, c.Current, Reverse));
	}
}

public class NegativeLookaround : Epsilon
{
	public bool Reverse;
	public FSM  Inner ~ _.Dispose();
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.PushState(.(Reverse ? c.Position - 1 : c.Position, Inner.Start, Reverse, true));
	}
}

public class NegativeLookaroundExit : Epsilon
{
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.CanBacktrack = false;
	}
}

public class LookaroundExit : Epsilon
{
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.PopState();
	}
}

public class RepeatEntry : Epsilon
{
	public int Cardinality = 1;
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.PushCardinality(Cardinality);
	}
}

public class LazyTryContinue : Epsilon
{
	public State BacktrackTo;
	public override void Apply(Cursor c)
	{
		c.Current = BacktrackTo;
		c.PushState(.(c.Position, Target, c.Reverse, true));
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
	public override bool Matches(Cursor c, StringView s) => (c.RepeatCount >= lowerBound);
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.PopCardinality();
	}
}

public class MaximumCardinality : Epsilon
{
	public int upperBound;
	public override bool Matches(Cursor c, StringView s) => (c.RepeatCount <= upperBound);
	public override void Apply(Cursor c)
	{
		base.Apply(c);
		c.RepeatCount++;
	}
}

public class LazyUntilMinimum : Epsilon
{
	public int lowerBound;
	public override bool Matches(Cursor c, StringView s) => (c.RepeatCount < lowerBound);
}

public class LazyMinimum : Epsilon
{
	public int lowerBound;
	public override bool Matches(Cursor c, StringView s) => (c.RepeatCount >= lowerBound);
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

