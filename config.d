module config;

import std.stdio;
static import std.file;
import std.string;

class Config
{
	private:
		enum Mode
		{
			NULL,
			HOST,
			JOIN
		}

		string[] autojoins;
		string[] authedhosts;
		Mode mode=Mode.NULL;

	public:
		void addAutoJoin(string autojoin) { this.autojoins ~= autojoin; }
		void addAuthedHost(string host) { this.authedhosts ~= host; }
		string[] getAutoJoins() const { return autojoins.dup; }
		string[] getAuthedHosts() const { return authedhosts.dup; }
		bool isAuthed(string host) const
		{
			foreach(string h ; authedhosts)
			{
				if(h==host) return true;
			}
			return false;
		}
		this(string configfile)
		{
			string txt;
			try {
				txt=std.file.readText(configfile);
			} catch(std.file.FileException e) {
				save(configfile);
				return;
			}
			scope auto array=splitLines(txt);
			foreach(string s ; array)
			{
				if(s=="[autojoin]")
				{
					mode=Mode.JOIN;
					continue;
				}
				else if(s=="[hosts]")
				{
					mode=Mode.HOST;
					continue;
				}
				switch(mode)
				{
					case Mode.JOIN:
						this.addAutoJoin(s);
						break;
					case Mode.HOST:
						this.addAuthedHost(s);
						break;
					default:
						throw new Exception("Config file is not well-formed.");
				}
			}
		}
		void save(string configfile)
		{
			std.file.write(configfile, "");
			std.file.append(configfile, "[autojoin]\n");
			foreach(string s ; autojoins)
			{
				std.file.append(configfile, s ~ "\n");
			}
			std.file.append(configfile, "[hosts]\n");
			foreach(string s ; authedhosts)
			{
				std.file.append(configfile, s ~ "\n");
			}
		}
}
