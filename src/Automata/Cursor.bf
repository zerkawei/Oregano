using System;
using System.Collections;
namespace Oregano.Automata;

public class Cursor
{
	public struct SavedState
	{
		[Bitfield<bool>(.Public, .Bits(1), "Reverse")]
		[Bitfield<bool>(.Public, .Bits(1), "CanBacktrack")]
		[Bitfield<int>(.Public, .Bits(54), "Position")]
		[Bitfield<uint8>(.Public, .Bits(8), "CardinalityStackSize")]
		private uint data;
		public State State;

		public this(int pos, State state, bool rev, bool canBacktrack = false, uint8 cStackSize = 0)
		{
			data = ?;
			State = state;
			Position = (int)pos;
			Reverse = rev;
			CanBacktrack = canBacktrack;
			CardinalityStackSize = cStackSize;
		}
	}

	public Range[] Groups ~ if(_ != null) delete _;

	private CompactList<SavedState> stateStack = .() ~ _.Dispose();
	private CompactList<int> cardinalityStack  = .() ~ _.Dispose();
	private ref SavedState CurPos => ref stateStack[stateStack.Count - 1];

	public ref int RepeatCount => ref cardinalityStack[cardinalityStack.Count - 1];
	public ref State Current
	{
		get => ref CurPos.State;
	}
	public int Position
	{
		get => CurPos.Position;
		set => CurPos.Position = value;
	}
	public bool Reverse
	{
		get => CurPos.Reverse;
		set => CurPos.Reverse = value;
	}
	public bool CanBacktrack
	{
		get => CurPos.CanBacktrack;
		set => CurPos.CanBacktrack = value;
	}

	public this(State start, int position, int groupCount)
 	{
		Groups  = new .[groupCount + 1];
		Groups[0].Start = position;
		stateStack.Add(.(position, start, false));
	}

	public this(Cursor parent)
	{
		Groups  = new .[parent.Groups.Count];

		parent.Groups.CopyTo(Groups);
		for(let pos in parent.stateStack)
		{
			stateStack.Add(pos);
		}

		for(let i in parent.cardinalityStack)
		{
			cardinalityStack.Add(i);
		}
	}

	public void PushCardinality(int cardinality)
	{
		cardinalityStack.Add(cardinality);
		CurPos.CardinalityStackSize++;
	}
	public void PopCardinality()
	{
		cardinalityStack.RemoveAt(cardinalityStack.Count - 1);
		CurPos.CardinalityStackSize--;
	}

	[Inline]
	public void PushState(SavedState pos) => stateStack.Add(pos);
	public void PopState()
	{
		while(CurPos.CardinalityStackSize > 0) PopCardinality();
		stateStack.RemoveAt(stateStack.Count - 1);
	}

	public bool MatchesString(StringView source, StringView match) => Reverse ? source[...Position].EndsWith(match) : source[Position...].StartsWith(match);
	public bool Inbounds(StringView s) => (Position < s.Length && Position >= 0);
}

