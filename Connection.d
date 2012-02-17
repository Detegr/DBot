import std.stdio;
import std.socket;
import std.array;
import std.string;
import std.format;
import std.utf;
import std.encoding;

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
			
			for(int i=0; i<ret.length; ++i)
			{
				if(ret[i]<'\u0000' || ret[i]>'\U0010FFFF') ret[i]='?';
			}
			return ret.idup.split("\n");//splitLines(ret.idup);
		}
		void Disconnect()
		{
			socket.shutdown(SocketShutdown.BOTH);
			socket.close();
		}
}
/*
class CommandExecuter
{
	static void function()[string] commands;
	static this()
	{
		commands["JOIN"]=&Join;
	}
	static void Join(Connection c, ParsedMessage msg)
	{
	}
}
*/
bool running=true;
void main()
{
	scope auto c = new Connection();
	c.Connect(new InternetAddress("irc.quakenet.org", 6667));
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
					ParsedMessage m=Irc.Parse(s);
					writeln(m);
				}
				catch(Exception e) {}
			}
		}
	}
}
