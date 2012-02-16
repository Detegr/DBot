import std.stdio;
import std.socket;

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
		Address[] address;

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
		void Recv()
		{
			ptrdiff_t recvd;
			char[BUFSIZE] buf = new char[BUFSIZE];
			do
			{
				recvd=socket.receive(buf); // socket.receive() will check buf's bounds.
				buf[recvd-2]=0; // Slice out \r\n
				writeln(buf);
			}
			while(recvd>0);
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
	c.Recv();
}
