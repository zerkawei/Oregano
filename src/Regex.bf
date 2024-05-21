using System.Collections;
using System;
namespace Oregano;

public class Regex
{
	private FSM compiledFsm ~ _.Dispose();
	private int groupCount;

	private List<Cursor>       cursors = new .() ~ DeleteContainerAndItems!(_);
	private List<StringView[]> matches = new .() ~ DeleteContainerAndItems!(_);

	public List<StringView[]> MatchAll(StringView s)
	{
		int startPos = 0;
		while(startPos < s.Length)
		{
			bool matched = false;
			cursors.ClearAndDeleteItems();
			cursors.Add(new .(s, compiledFsm.Start, startPos, groupCount));
			while(!(matched = Step(ref startPos)) && cursors.Count > 0) {}

			if(!matched) startPos++;
		}

		return matches;
	}

	private bool Step(ref int startPos)
	{
		var i = 0;
		var foundMatch = false;
		while(i < cursors.Count && !foundMatch)
		{
			var c = cursors[i];
			if(!StepCursor(c))
			{
				if(c.Current == compiledFsm.End)
				{
					foundMatch = true;
					let match = new StringView[c.Groups.Count + 1];
					match[0] = c.String[startPos..<c.Position];
					for(let g < c.Groups.Count)
					{
						match[g+1] = c.String[c.Groups[g].Start..<c.Groups[g].End];
					}
					matches.Add(match);
					startPos = c.Position;
				}
				cursors.RemoveAt(i);
				delete c;
			}
			else
			{
				i++;
			}
		}

		return foundMatch;
	}

	private bool StepCursor(Cursor c)
 	{
		if(c.Position >= c.String.Length) return false;

		var hasTransitioned = false;
		let cursorStart     = c.Position; 
        for(let t in c.Current.Transitions)
		{
		    if(t.Matches(c) case .Accepted(let count))
			{
				if(hasTransitioned)
				{
					let nCur = new Cursor(c.String, t.Target, cursorStart + count, c.Groups.Count);
					c.Groups.CopyTo(nCur.Groups);
					cursors.Add(nCur);
  				}
				else
				{
					c.Position += count;
					c.Current   = t.Target;

					hasTransitioned = true;
				}
			}
		}
		return hasTransitioned;
	}
}