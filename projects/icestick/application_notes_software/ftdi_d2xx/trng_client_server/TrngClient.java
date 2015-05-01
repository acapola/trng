import java.io.Console;
import java.net.* ;
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;


public class TrngClient{
	private final static int PACKETSIZE = 1024*4 ;

	public static void main( String args[] ){
		// Check the arguments
		if( args.length != 2 ){
			System.out.println( "usage: java TrngClient <host> <port>" ) ;
			return ;
		}

		DatagramSocket socket = null ;

		try{
			Console c = System.console();
			if (c == null) {
				System.err.println("No console.");
				System.exit(1);
			}
			
			// Convert the arguments first, to ensure that they are valid
			InetAddress host = InetAddress.getByName( args[0] ) ;
			int port         = Integer.parseInt( args[1] ) ;

			// Construct the socket
			socket = new DatagramSocket() ;
			// Set a receive timeout, 2000 milliseconds
			socket.setSoTimeout( 2000 ) ;

			int req_cnt=0;
			
			while(true){
				String requestStr = c.readLine("\nEnter amount of random data to request (in mega bytes): ");
				String filename = "reply_" + req_cnt + ".dat";
				OutputStream output = null;
				byte [] request = new byte[3];
				int requested_len = PACKETSIZE;			
				request[0] = (byte)(requested_len & 0xFF);
				request[1] = (byte)((requested_len>>8) & 0xFF);
				request[2] = (byte)((requested_len>>16) & 0xFF);
				long len = Long.decode(requestStr)*1024*1024;
				double mbits = len / (1024*1024/8);
				long start = System.nanoTime();
				try {
					output = new BufferedOutputStream(new FileOutputStream(filename));
					int cnt=0;
					while(len>0){
						if(len<requested_len){
							requested_len = (int)len;
							request[0] = (byte)(requested_len & 0xFF);
							request[1] = (byte)((requested_len>>8) & 0xFF);
							request[2] = (byte)((requested_len>>16) & 0xFF);
						}
						DatagramPacket packet = new DatagramPacket( request, request.length, host, port ) ;
						socket.send(packet);// Send request
						packet.setData(new byte[requested_len]);// Prepare the packet for receive
						socket.receive(packet);// Wait for a response from the server
						output.write(packet.getData());
						len-=requested_len;
						cnt++;if(cnt%10==0) System.out.print(".");
					}
				}finally {
					if(output!=null) output.close();
				}
				System.out.println();
				long end = System.nanoTime();
				double exec_time = (end-start)/(1000L*1000*1000);
				double mbits_per_sec = mbits / exec_time;
				System.out.println("Reply time is: "+ exec_time +"s, "+ mbits_per_sec +"MBits/s ("+ (mbits_per_sec/8) +"MBytes/s)");
				req_cnt++;
			}
		}
		catch( Exception e ){
			System.out.println( e ) ;
		}
		finally{
			if( socket != null ) socket.close() ;
		}
	}
}
