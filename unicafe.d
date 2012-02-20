import etc.c.curl;
import std.string;
import std.stdio;
import std.xml;
import std.datetime;
import std.array;

class Curl
{
	private:
		char[] data;
		CURL* handle;

		this()
		{
			handle=curl_easy_init();
		}
		~this()
		{
			curl_easy_cleanup(handle);
		}
		string get(string url)
		{
			curl_easy_setopt(handle, CurlOption.url, url.toStringz);
			curl_easy_setopt(handle, CurlOption.writefunction, &callback);
			curl_easy_setopt(handle, CURLOPT_WRITEDATA, &data);
			curl_easy_perform(handle);
			return data.idup;
		}
}

size_t callback(void* buffer, size_t size, size_t nmemb, void* user)
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

class Unicafe
{
	string urlbase="http://www.unicafe.fi/lounastyokalu/index.php?option=com_ruokalista&Itemid=29&task=lounaslista_haku&week=%d&day=%d&year=%d&rid=%d&lang=1";
	string[] getFoods(int id)
	{
		auto time=Clock.currTime();
		string url=format(urlbase, time.isoWeek(), time.dayOfWeek(), time.year(), id);
		scope auto curl = new Curl();
		string source=curl.get(url);
		auto doc = new DocumentParser(source);
		doc.onEndTag["li"] = (in Element e)
		{
			string s=e.text().split("<span")[0];
			writeln(s);
		};
		doc.parse();
		return null;
	}
}

void main()
{
	auto u = new Unicafe();
	u.getFoods(10);
	//scope auto curl = new Curl();
	//string source=curl.get();
	// isoWeek();
	//auto doc = new Document(source);
	//doc.check();
	//doc.onEndTag["span"] = (in Element e){writeln(e);};
	//doc.parse();
	//writeln(source);
}
