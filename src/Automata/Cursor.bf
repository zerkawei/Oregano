using System;
using System.Collections;
namespace Oregano.Automata;

public class Cursor
{
	public struct SavedPos
	{
		[Bitfield<bool>(.Public, .Bits(1), "Reverse")]
		[Bitfield<bool>(.Public, .Bits(1), "CanBacktrack")]
		[Bitfield<int>(.Public, .Bits(62), "Position")]
		private uint data;
		public State State;

		public this(int pos, State state, bool rev, bool canBacktrack = false)
		{
			data = ?;
			State = state;
			Position = (int)pos;
			Reverse = rev;
			CanBacktrack = canBacktrack;
		}
	}

	public CompactList<SavedPos> Positions = .() ~ _.Dispose();
	public CompactList<int> RepeatCount = .() ~ _.Dispose();
	public Range[] Groups ~ if(_ != null) delete _;

	public ref State Current
	{
		get => ref Positions[Positions.Count - 1].State;
	}
	public int Position
	{
		get => Positions[Positions.Count - 1].Position;
		set => Positions[Positions.Count - 1].Position = value;
	}
	public bool Reverse
	{
		get => Positions[Positions.Count - 1].Reverse;
		set => Positions[Positions.Count - 1].Reverse = value;
	}
	public bool CanBacktrack
	{
		get => Positions[Positions.Count - 1].CanBacktrack;
		set => Positions[Positions.Count - 1].CanBacktrack = value;
	}

	public this(State start, int position, int groupCount)
 	{
		Groups  = new .[groupCount + 1];
		Groups[0].Start = position;
		Positions.Add(.(position, start, false));
	}

	public this(Cursor parent)
	{
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

