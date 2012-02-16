import std.stdio;
import std.socket;
import std.array;

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
}

class Connection
{
	private:
		immutable auto BUFSIZE=1024;
		string nick;
		string realname;
		TcpSocket socket;

		void PingPong(char[] msg)
		{
			if(msg[0 .. 4]=="PING")
			{
				msg[1]='O';
				Send(msg);
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
			socket.send(msg);
		}
		void Send(char[] msg)
		{
			socket.send(msg);
		}
		char[][] Recv()
		{
			ptrdiff_t recvd;
			char[BUFSIZE] buf = new char[BUFSIZE];
			recvd=socket.receive(buf); // socket.receive() will check buf's bounds.
			// However, if recvd>BUFSIZE, some funny things will probably occur...
			return buf[0 .. recvd-2].split("\r\n"); // Slice out the last \r\n
		}
		void Disconnect()
		{
			socket.shutdown(SocketShutdown.BOTH);
			socket.close();
		}
}

void main()
{
	scope auto c = new Connection();
	c.Connect(new InternetAddress("irc.quakenet.org", 6667));
	while(true)
	{
		char[][] msgs=c.Recv();
		foreach(char[] s ; msgs)
		{
			c.PingPong(s);
			writeln(s);
		}
	}
}
