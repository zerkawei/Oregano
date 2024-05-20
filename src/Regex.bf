using System.Collections;
using System;
namespace Oregano;

public class Regex
{
	private FSM compiledFsm;
	private int groupCount;

	private List<Cursor>       cursors;
	private List<StringView[]> matches;


	private IEnumerable<StringView[]> MatchAll(StringView s)
	{
		cursors.Add(new .(s, compiledFsm.Start, 0, groupCount));

		int startPos = 0;
		while(startPos < s.Length)
		{
			while(Step(startPos, out startPos)) {}
		}

		return matches;
	}	

	private bool Step(int startPos, out int lastPos)
	{
		lastPos = startPos + 1;

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
					match[0] = c.String[startPos...c.Position];
					for(let g < c.Groups.Count)
					{
						match[g+1] = c.String[c.Groups[g].Start...c.Groups[g].End];
					}
					matches.Add(match);
					lastPos = c.Position;
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

private enum 