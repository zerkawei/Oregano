using System.Collections;
using System;
using Oregano.Compiler;
namespace Oregano;

public class Regex
{
	private FSM compiledFsm ~ _.Dispose();
	private int groupCount;

	private List<Cursor>         cursors = new .() ~ DeleteContainerAndItems!(_);
	private List<StringView[]>   matches = new .() ~ DeleteContainerAndItems!(_);
	private List<CharacterClass> classes ~ if(_ != null) DeleteContainerAndItems!(_);

	private this() {}

	public static Regex Compile(StringView regex)
 	{
		let p = scope Parser(regex);
		if(p.ParseExpressions() case .Ok(let ast))
		{
			let res = new Regex();
			res.compiledFsm = ast.Compile();
			res.groupCount  = p.GroupCount;
			res.classes     = p.Classes;

			delete ast;
			return res;
		}
		return null;
	}

	public List<StringView[]> MatchAll(StringView s)
	{
		int startPos = 0;
		while(startPos < s.Length)
		{
			bool matched = false;
			cursors.ClearAndDeleteItems();
			cursors.Add(new .(compiledFsm.Start, startPos, groupCount));
			while(!(matched = Step(ref startPos, s)) && cursors.Count > 0) {}

			if(!matched) startPos++;
		}

		return matches;
	}

	private bool Step(ref int startPos, StringView s)
	{
		var i = 0;
		var foundMatch = false;
		while(i < cursors.Count && !foundMatch)
		{
			var c = cursors[i];
			if(!StepCursor(c, s))
			{
				if(c.Current == compiledFsm.End)
				{
					foundMatch = true;
					let match = new StringView[c.Groups.Count + 1];
					match[0] = s[startPos..<c.Position];
					for(let g < c.Groups.Count)
					{
						match[g+1] = s[c.Groups[g].Start..<c.Groups[g].End];
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

	private bool StepCursor(Cursor c, StringView s)
 	{
		var hasTransitioned = false;
		let cursorStart     = c.Position; 
        for(let t in c.Current.Transitions)
		{
		    if(t.Matches(c, s) case .Accepted(let count))
			{
				if(hasTransitioned)
				{
					let nCur = new Cursor(c, t.Target, c.Reverse ? cursorStart - count : cursorStart + count);
					cursors.Add(nCur);
  				}
				else
				{
					c.Position += c.Reverse ? -count : count;
					c.Current   = t.Target;

					hasTransitioned = true;
				}
			}
		}
		return hasTransitioned;
	}
}