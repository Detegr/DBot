import std.stdio;
import std.socket;
import std.array;
import std.string;

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
	static void Parse(string msg)
	{
		if(msg[0]!=':' || indexOf(msg, "PRIVMSG")==-1 || indexOf(msg, '!')==-1) return;
		char[] nick, host, cmd, channel, data;
		char[] msgd=msg.dup;
		nick=msgd[1 .. indexOf(msg, '!')];
		host=msgd[indexOf(msg,'!')+1 .. indexOf(msg, ' ')];
		cmd="PRIVMSG".dup;
		channel=msgd[indexOf(msg,cmd)+cmd.length+1 .. lastIndexOf(msg,':')-1];
		data=msgd[lastIndexOf(msg,':')+1 .. msg.length];
		writeln("NICK: " ~ nick ~ "\nHOST: " ~ host ~ "\nCMD: " ~ cmd ~ "\nCHANNEL: " ~ channel ~ "\nDATA: " ~ data);
	}
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
			return splitLines(ret.idup);
		}
		void Disconnect()
		{
			socket.shutdown(SocketShutdown.BOTH);
			socket.close();
		}
}

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
			writeln(s);
			c.PingPong(s);
			Irc.Parse(s);
		}
	}
}
