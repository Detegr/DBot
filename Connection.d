import std.stdio;
import std.socket;

class Connection
{
	TcpSocket socket;
	Address[] address;

	this()
	{
		socket = new TcpSocket(AddressFamily.INET);
	}
	~this()
	{
		Disconnect();
	}
	void Connect(Address addr)
	{
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
