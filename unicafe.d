module unicafe;
import etc.c.curl;
import std.string;
import std.stdio;
import std.xml;
import std.datetime;
import std.array;
static import std.regex;

extern(C)
{
	static size_t callback(void* buffer, size_t size, size_t nmemb, void* user)
	{
		char[] buf = new char[nmemb];
		char* charbuf=cast(char*) buffer;

		int i;
		for(i=0; i<nmemb; ++i)
		{
			buf[i]=charbuf[i];
		}
		*cast(char[]*)user ~= buf;

		return i;
	}
}

class Curl
{
	private:
		char[] data;
		CURL* handle;

		this()
		{
			handle=curl_easy_init();
			if(!handle) writeln("INIT FAILED!!");
		}
		~this()
		{
			curl_easy_cleanup(handle);
		}
		string get(string url)
		{
			curl_easy_setopt(handle, CurlOption.writefunction, &callback);
			curl_easy_setopt(handle, CurlOption.url, url.toStringz);
			curl_easy_setopt(handle, CURLOPT_WRITEDATA, &data);
			curl_easy_perform(handle);
			return data.idup;
		}
}


class Unicafe
{
	enum Restaurant
	{
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
