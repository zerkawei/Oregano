using System;
namespace Oregano;

public interface IExpression
{
	public FSM Compile();
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
	public IExpression Child;

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

public class OrExpr : IExpression
{
	public IExpression Left;
	public IExpression Right;

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
	public IExpression Child;

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
	public IExpression Left;
	public IExpression Right;

	public FSM Compile()
	{
		let lfsm = Left.Compile();
		let rfsm = Right.Compile();

		lfsm.End.Transitions.Add(new Epsilon(){Target = rfsm.Start});

		return .(lfsm.Start, rfsm.End);
	}
}