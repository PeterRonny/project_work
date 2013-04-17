package us.sosia.video.stream.agent;

import java.awt.Dimension;
import java.net.InetSocketAddress;

import com.github.sarxos.webcam.Webcam;

public class StreamServer {

	/**
	 * @author kerr
	 */
	public static void main(String[] args) {
		Webcam.setAutoOpenMode(true);
		Webcam webcam = Webcam.getDefault();
		Dimension dimension = new Dimension(320,240);
		webcam.setViewSize(dimension);
		
		StreamServerAgent serverAgent = new StreamServerAgent(webcam, dimension);
		serverAgent.start(new InetSocketAddress("192.168.0.9", 20000));
	}

}