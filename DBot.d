module DBot;

import std.stdio;
import std.socket;
import std.array;
import std.string;
import std.format;
import std.utf;
import std.encoding;
import std.datetime;
import unicafe;

class Irc
{
	static string User(Connection c)
	{
		return Message("USER " ~ c.realname ~ " " ~ c.realname ~ " * :" ~ c.realname);
	}
	static string Nick(Connection c)
	{
		return Message("NICK " ~ c.nick);
	}
	static string Message(string msg)
	{
		return (msg ~ "\r\n");
	}
	static char[] Message(char[] msg)
	{
		return (msg ~ "\r\n");
	}
	static string PrivMsg(string channel, string msg)
	{
		return Irc.Message("PRIVMSG " ~ channel ~ " :" ~ msg);
	}
	static ParsedMessage Parse(string msg)
	{
		if(msg[0]!=':' || indexOf(msg, "PRIVMSG")==-1 || indexOf(msg, '!')==-1) throw new Exception("Not a PRIVMSG");
		return new ParsedMessage(msg);
	}
}

class ParsedMessage
{
	private:
		string nick, host, cmd, channel, data;
	public:
		this(string msg)
		{
			formattedRead(msg, ":%s!%s %s %s :%s", &nick, &host, &cmd, &channel, &data);
		}
		string toString()
		{
			return ("NICK: " ~ nick ~ "\nHOST: " ~ host ~ "\nCMD: " ~ cmd ~ "\nCHANNEL: " ~ channel ~ "\nDATA: " ~ data).idup;
		}
}

class ServerMessage
{
	private:
		string msg;
	public:
		this(ParsedMessage msg)
		{
			this.msg = Irc.Message(":"~msg.nick~"!"~msg.host~" "~msg.cmd~" "~msg.channel~" :"~msg.data);
		}
		string toString() { return msg; }
}


class Connection
{
	private:
		immutable auto BUFSIZE=1024;
		string nick;
		string realname;
		TcpSocket socket;

		void PingPong(string msg)
		{
			if(msg.length>4 && msg[0 .. 4]=="PING")
			{
				char[] smsg=msg.dup;
				smsg[1]='O';
				Send(Irc.Message(smsg));
			}
		}

	public:
		this(string nick="DBot", string realname="DBot")
		{
			this.nick=nick;
			this.realname=realname;
			socket = new TcpSocket(AddressFamily.INET);
		}
		~this()
		{
			Disconnect();
		}
		void Connect(scope InternetAddress addr)
		{
			writeln("Connecting to " ~ addr.toHostNameString() ~ ":" ~ addr.toPortString());
			socket.connect(addr);
			Send(Irc.Nick(this));
			Send(Irc.User(this));
		}
		void Send(const string msg)
		{
			//writeln("Sent: " ~ msg);
			socket.send(msg);
		}
		void Send(char[] msg)
		{
			//writeln("Sent: " ~ msg);
			socket.send(msg);
		}
		string[] Recv()
		{
			ptrdiff_t recvd;
			char[BUFSIZE] buf = new char[BUFSIZE];
			char[] ret;
			do
			{
				recvd=socket.receive(buf);
				if(!ret) ret=replace(buf[0 .. recvd], "\r\n", "\n");
				else ret=ret ~ replace(buf[0 .. recvd], "\r\n", "\n");
			} while(recvd==BUFSIZE || ret[ret.length-1]!='\n');
			return ret.idup.split("\n");
		}
		void Disconnect()
		{
			socket.shutdown(SocketShutdown.BOTH);
			socket.close();
		}
}
class CommandExecuter
{
	static void function(Connection c, ParsedMessage msg)[string] exec;
	static this()
	{
		exec["JOIN"]=&Join;
		exec["DIE"]=&Die;
		exec["!unicafe"]=&unicafe;
		exec["!unicafe -k"]=&unicafec;
	}
	static void Join(Connection c, ParsedMessage msg)
	{
		c.Send(Irc.Message(msg.data));
	}
	static void Die(Connection c, ParsedMessage msg)
	{
		running=false;
	}
	static void unicafe(Connection c, ParsedMessage msg)
	{
		auto time = Clock.currTime;
		c.Send(Irc.PrivMsg(msg.channel, "Food for: " ~ format("%d.%d.%d", time.day(), time.month(), time.year())));
		c.Send(Irc.PrivMsg(msg.channel, "-----------"));
		c.Send(Irc.PrivMsg(msg.channel, "Chemicum:"));
		string[] foods=Unicafe.getFoods(Unicafe.Restaurants.CHEMICUM);
		foreach(string food ; foods) c.Send(Irc.PrivMsg(msg.channel, food));
		c.Send(Irc.PrivMsg(msg.channel, "-----------"));
		c.Send(Irc.PrivMsg(msg.channel, "Exactum:"));
		foods=Unicafe.getFoods(Unicafe.Restaurants.EXACTUM);
		foreach(string food ; foods) c.Send(Irc.PrivMsg(msg.channel, food));
	}
	static void unicafec(Connection c, ParsedMessage msg)
	{
		c.Send(Irc.PrivMsg(msg.channel, "-k is not currently supported."));
	}
}

bool running=true;
void main()
{
	scope auto c = new Connection();
	c.Connect(new InternetAddress("irc.quakenet.org", 6667));
	scope auto command = CommandExecuter.exec;
	while(running)
	{
		string[] msgs=c.Recv();
		foreach(string s ; msgs)
		{
			if(s.length>=5 && s[0 .. 5]=="ERROR") running=false;
			else if(s.length)
			{
				writeln(s);
				c.PingPong(s);
				try
				{
					scope ParsedMessage m=Irc.Parse(s);
					scope string cmd = m.data.split(" ")[0];
					command[cmd](c, m);
				}
				catch(Exception e) {}
				catch {writeln("Suddenly an error.");}
			}
		}
	}
}
