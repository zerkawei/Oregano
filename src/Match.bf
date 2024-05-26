using System;
using System.Collections;
namespace Oregano;

public struct Match : IDisposable
{
	private Dictionary<StringView, int> namedCaptures;
	public StringView Source;
	public Range[] Captures;

	public this(StringView source, Range[] captures, Dictionary<StringView, int> names = null)
	{
		Source = source;
		Captures = captures;
		namedCaptures = names;
	}

	public StringView this[int i]           => Source[Captures[i]];
	public StringView this[StringView name] => this[namedCaptures[name]];

	public void Dispose() { delete Captures; }
}