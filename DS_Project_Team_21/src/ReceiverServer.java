import java.io.IOException;
import com.ericsson.otp.erlang.*;

public class ReceiverServer implements Runnable {	

	@Override
	public void run() {
		IPAddress ip = new IPAddress();
		String myIP = ip.getIPaddress();
		String receiver_server = "david@"; //"receiver_server@"; 
		OtpNode node = null;
		
		try {
			node = new OtpNode(receiver_server.concat(myIP), "test");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		//the mbox and the OtpNode above should be the same as the client created in Messaging.java, I think...?
        OtpMbox mbox = node.createMbox("david");//"receiver_server"); //just to make it easier to follow the same format
        OtpErlangAtom SHUTDOWN = new OtpErlangAtom("shutdown");
        System.out.println("Receiver server ("+node.toString()+") started\n");
        
        while (true) 
        {
            OtpErlangObject message = null;
			try {
				//System.out.println("Waiting to receive...\n");
				message = mbox.receive();
				//System.out.println("Got message "+message+"\n");
			} catch (OtpErlangExit e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (OtpErlangDecodeException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			System.out.format("received %s%n", message);
            if (SHUTDOWN.equals(message)) 
            {
                System.out.format("%s shutting down...%n", mbox.self());
                break;
            } 
            else if (message instanceof OtpErlangTuple) 
            {
                OtpErlangTuple messageTuple = (OtpErlangTuple) message;
                //System.out.println("message arity is "+messageTuple.arity()+"\n");
                //System.out.println("first element is "+messageTuple.elementAt(0)+"\n");
                //if (messageTuple.arity() == 2 && messageTuple.elementAt(0) instanceof OtpErlangPid)
                if (messageTuple.arity() == 2 && messageTuple.elementAt(0) instanceof OtpErlangTuple) 
                {
                	OtpErlangTuple payload = (OtpErlangTuple) messageTuple.elementAt(0);
                	System.out.println("Received a message of type "+payload.elementAt(2)+" from "+payload.elementAt(0)+"\n");
                    /*OtpErlangPid sender = (OtpErlangPid) messageTuple.elementAt(0);
                    OtpErlangObject sendersMessage = messageTuple.elementAt(1);
                    mbox.send(sender, sendersMessage);*/
                }
            }
        }	
	}
}
