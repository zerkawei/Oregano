using System;
using System.Collections;
namespace Oregano.Automata;

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
	public Range[] Groups ~ if(_ != null) delete _;

	public int Position
	{
		get => (int)Positions[Positions.Count - 1].Position;
		set => Positions[Positions.Count - 1].Position = (uint)value;
	}
	public bool Reverse
	{
		get => Positions[Positions.Count - 1].Reverse;
		set => Positions[Positions.Count - 1].Reverse = value;
	}

	public this(State start, int position, int groupCount)
 	{
		Current = start;
		Groups  = new .[groupCount + 1];
		Groups[0].Start = position;
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

