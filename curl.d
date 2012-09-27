module curl;
import etc.c.curl;
import std.string;
import std.stdio;

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
	public:
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
		string post(string url, string postdata)
		{
			curl_easy_setopt(handle, CurlOption.writefunction, &callback);
			curl_easy_setopt(handle, CURLOPT_WRITEDATA, &data);
			curl_easy_setopt(handle, CurlOption.url, url.toStringz);
			curl_easy_setopt(handle, CurlOption.postfields, postdata.toStringz);
			curl_easy_perform(handle);
			return data.idup;
		}
}

