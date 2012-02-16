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
			if(msg.length>4 && msg[0 .. 4]=="PING")
			{
				msg[1]='O';
				Send(Irc.Message(msg));
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
		char[][] Recv()
		{
			ptrdiff_t recvd;
			char[BUFSIZE] buf = new char[BUFSIZE];
			char[] ret;
			do
			{
				recvd=socket.receive(buf); // socket.receive() will check buf's bounds.
				if(!ret) ret=replace(buf[0 .. recvd].dup, "\r\n", "\n");
				else ret=ret ~ replace(buf[0 .. recvd].dup, "\r\n", "\n");
			} while(recvd==BUFSIZE || ret[ret.length-1]!='\n');
			return split(ret,"\n");
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
			if(s.length) // Ugh, ugly :(
			{
				writeln(s);
				c.PingPong(s);
			}
		}
	}
}
