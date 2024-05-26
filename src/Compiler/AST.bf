using System;
using Oregano.Automata;
namespace Oregano.Compiler;

public interface IExpression
{
	public FSM Compile();
}

public class CharExpr : IExpression
{
	public char8 Char;
	public FSM Compile()
	{
		let start = new State();
		let end   = new State();

		start.Transitions.Add(new CharacterMatch(){Target = end, Character = Char});

		return .(start, end);
	}
}

public class StringExpr : IExpression
{
	public StringView String;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();

		start.Transitions.Add((String.Length > 1) ? (.)new StringMatch(){Target = end, String = String} : (.)new CharacterMatch(){Target = end, Character = String[0]});

		return .(start, end);
	}
}

public class StarExpr : IExpression
{
	public IExpression Child ~ delete _;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();
		let fsm   = Child.Compile();

		fsm.End.Transitions.Add(new Epsilon(){Target = fsm.Start});
		fsm.End.Transitions.Add(new Epsilon(){Target = end});
		start.Transitions.Add(new Epsilon(){Target = fsm.Start});
		start.Transitions.Add(new Epsilon(){Target = end});

		return .(start, end);
	}
}

public class PlusExpr : IExpression
{
	public IExpression Child ~ delete _;

	public FSM Compile()
	{
		let end   = new State();
		let fsm   = Child.Compile();

		fsm.End.Transitions.Add(new Epsilon(){Target = fsm.Start});
		fsm.End.Transitions.Add(new Epsilon(){Target = end});

		return .(fsm.Start, end);
	}
}

public class OptionalExpr : IExpression
{
	public IExpression Child ~ delete _;

	public FSM Compile()
	{
		let fsm = Child.Compile();

		fsm.Start.Transitions.Add(new Epsilon(){Target = fsm.End});

		return fsm;
	}
}

public class CardinalityExpr : IExpression
{
	public IExpression Child ~ delete _;
	public Range       Cardinality;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();
		let fsm   = Child.Compile();

		if(Cardinality.Start == 0)
		{
			start.Transitions.Add(new Epsilon(){Target = end});
		}

		start.Transitions.Add(new RepeatEntry(){Target = fsm.Start});
		fsm.End.Transitions.Add(new MaximumCardinality(){upperBound = Cardinality.End, Target = fsm.Start});
		fsm.End.Transitions.Add(new MinimumCardinality(){lowerBound = Cardinality.Start, Target = end});

		return .(start, end);
	}
}

public class OrExpr : IExpression
{
	public IExpression Left  ~ delete _;
	public IExpression Right ~ delete _;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();
		let lfsm  = Left.Compile();
		let rfsm  = Right.Compile();

		start.Transitions.Add(new Epsilon(){Target = lfsm.Start});
		start.Transitions.Add(new Epsilon(){Target = rfsm.Start});
		lfsm.End.Transitions.Add(new Epsilon(){Target = end});
		rfsm.End.Transitions.Add(new Epsilon(){Target = end});

		return .(start, end);
	}
}

public class GroupExpr : IExpression
{
	public int         Group;
	public IExpression Child ~ delete _;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();
		let fsm   = Child.Compile();

		start.Transitions.Add(new GroupEntry(){Target = fsm.Start, Group = Group});
		fsm.End.Transitions.Add(new GroupExit(){Target = end, Group = Group});

		return .(start, end);
	}
}

public class BackreferenceExpr : IExpression
{
	public int Group;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();

		start.Transitions.Add(new Backreference(){Target = end, Group = Group});

		return .(start, end);
	}
}

public class ConcatExpr : IExpression
{
	public IExpression Left  ~ delete _;
	public IExpression Right ~ delete _;

	public FSM Compile()
	{
		let lfsm = Left.Compile();
		let rfsm = Right.Compile();

		lfsm.End.Transitions.Add(new Epsilon(){Target = rfsm.Start});

		return .(lfsm.Start, rfsm.End);
	}
}

public class LookaroundExpr : IExpression
{
	public bool Behind;
	public bool Negative;
	public IExpression Child ~ delete _;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();
		var fsm   = Child.Compile();

		if(Behind)
		{
			fsm.Reverse();
		}

		if(!Negative)
		{
			start.Transitions.Add(new LookaroundEntry(){Target = fsm.Start, Reverse = Behind});
			fsm.End.Transitions.Add(new LookaroundExit(){Target = end});
		}
		else
		{
			start.Transitions.Add(new NegativeLookaround(){Target = end, Reverse = Behind, Inner = fsm});
		}
		
		return .(start, end);
	}
}

public class CharClassExpr : IExpression
{
	public CharacterClass CharClass;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();

		start.Transitions.Add(new ClassMatch(){Target = end, CharClass = CharClass});

		return .(start, end);
	}
}

public class AnchorExpr : IExpression
{
	public enum AnchorType
	{
		LineStart,
		LineEnd,
		StringStart,
		StringEnd,
		WordBoundary
	}

	public AnchorType Type;

	public FSM Compile()
	{
		let start = new State();
		let end   = new State();

		switch(Type)
		{
		case .LineStart:
			start.Transitions.Add(new LineStart(){Target = end});
		case .LineEnd:
			start.Transitions.Add(new LineEnd(){Target = end});
		case .StringStart:
			start.Transitions.Add(new StringStart(){Target = end});
		case .StringEnd:
			start.Transitions.Add(new StringEnd(){Target = end});
		case .WordBoundary:
			start.Transitions.Add(new WordBoundary(){Target = end});
		}

		return .(start, end);
	}
}