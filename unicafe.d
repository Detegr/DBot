module unicafe;
import std.string;
import std.stdio;
import std.xml;
import std.datetime;
import std.array;
static import std.regex;
import curl;

class Unicafe
{
	enum Restaurant
	{
		PORTHANIA=3,
		PAARAKENNUS=4,
		CHEMICUM=10,
		EXACTUM=11
	}
	static string urlbase="http://www.unicafe.fi/lounastyokalu/index.php?option=com_ruokalista&Itemid=29&task=lounaslista_haku&week=%d&day=%d&year=%d&rid=%d&lang=1";
	static string[] getFoods(Restaurant id)
	{
		string[] foods;
		auto time=Clock.currTime();
		string url=format(urlbase, time.isoWeek(), time.dayOfWeek(), time.year(), id);
		scope auto curl = new Curl();
		string source=curl.get(url);
		auto doc = new DocumentParser(source);
		doc.onEndTag["li"] = (in Element e)
		{
			char[] s=e.text().split("<span")[0].dup;
			char[][] food=std.regex.split(s, std.regex.regex(` *\(.*\)`));

			string type="";
			try
			{
				auto match = std.regex.match(e.text(), std.regex.regex(`Maukkaasti|Edullisesti|Makeasti|Kevyesti`));
				if(match.captures.length>0) type=match.front.hit;
			}
			catch {}

			char[] parsedfood;
			foreach(char[] f ; food)
			{
				parsedfood ~= f;
			}
			if(type.length) parsedfood ~= " - " ~ type;
			foods ~= parsedfood.idup;
		};
		doc.parse();
		return foods;
	}
}
