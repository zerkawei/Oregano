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
			Cursor candidate = null;

			cursors.ClearAndDeleteItems();
			cursors.Add(new .(compiledFsm.Start, startPos, groupCount));

			while(cursors.Count > 0)
			{
				Step(ref candidate, s);
			}

			if(candidate != null)
			{
				let match = new StringView[candidate.Groups.Count + 1];
				match[0] = s[startPos..<candidate.Position];
				for(let g < candidate.Groups.Count)
				{
					match[g+1] = s[candidate.Groups[g].Start..<candidate.Groups[g].End];
				}
				matches.Add(match);
				startPos = candidate.Position;

				delete candidate;
			}
			else { startPos++; }
		}

		return matches;
	}

	private void Step(ref Cursor candidate, StringView s)
	{
		var i = 0;
		
		while(i < cursors.Count)
		{
			var c = cursors[i];
Step:		if(!StepCursor(c, s))
			{
				if(c.Current == compiledFsm.End)
				{
					if(candidate == null || candidate.Position < c.Position)
					{
						if(candidate != null) delete candidate;
						candidate = c;
					}
					else
					{
						defer :Step delete c;
					}
				}
				else
				{
					defer :Step delete c;
				}
				cursors.RemoveAt(i);
			}
			else { i++; }
		}
	}

	private bool StepCursor(Cursor c, StringView s)
 	{
		Transition firstTransition = null;

        for(let t in c.Current.Transitions)
		{
		    if(t.Matches(c, s))
			{
				if(firstTransition != null)
				{
					let nCur = new Cursor(c);
					t.Apply(nCur);
					cursors.Add(nCur);
  				}
				else
				{
					firstTransition = t;
				}
			}
		}

		firstTransition?.Apply(c);
		return firstTransition != null;
	}
}