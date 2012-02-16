import std.stdio;
import std.socket;

class Connection
{
	string nick;
	string realname;
	TcpSocket socket;
	Address[] address;

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
}
