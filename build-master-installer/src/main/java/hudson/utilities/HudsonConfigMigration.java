package hudson.utilities;

import java.io.File;
import java.io.FileOutputStream;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Migrate old hudson slaves and views configuration from config.xml to the current installed hudson.
 * 
 * @author hui-min.chen@hp.com
 *
 */

public class HudsonConfigMigration {
	private static final String HUDSON_CONFIG_SLAVES = "slaves";
	private static final String HUDSON_CONFIG_VIEWS = "views";
	private static final String HUDSON_CONFIG_ROOT = "hudson";

	public static void main(String[] args) {
		if (args.length < 2) {
			System.out.println("Please provide both old hudson config.xml and current installed one path.");
			return;
		}
		File oldConfigXml = null;
		File currentConfigXml = null;

		if (args[0] != null && !args[0].trim().isEmpty()) {
			oldConfigXml = new File(args[0].trim());
		} else {
			System.out.println("Please provide valid old config.xml file path.");
			return;
		}

		if (args[1] != null && !args[1].trim().isEmpty()) {
			currentConfigXml = new File(args[1].trim());
		} else {
			System.out.println("Please provide valid current installed config.xml file path.");
			return;
		}
		if (oldConfigXml != null && oldConfigXml.exists() && currentConfigXml != null && currentConfigXml.exists()) {
			DocumentBuilderFactory domFac = DocumentBuilderFactory.newInstance();			
			try {
				DocumentBuilder domBuilder = domFac.newDocumentBuilder();				
				Document oldConfigDoc = domBuilder.parse(oldConfigXml);
				Document currentConfigDoc = domBuilder.parse(currentConfigXml);
				Element oldHudsonRoot = oldConfigDoc.getDocumentElement();
				Node oldSlaves = oldHudsonRoot.getElementsByTagName(HUDSON_CONFIG_SLAVES).item(0);
				Node oldViews = oldHudsonRoot.getElementsByTagName(HUDSON_CONFIG_VIEWS).item(0);
				Element currentHudsonRoot = currentConfigDoc.getDocumentElement();
				NodeList currentHudsonRootChildNodes = currentHudsonRoot.getChildNodes();
				
				//create a new document to combine the old and current document info
				Document newCreatedConfigDoc = domBuilder.newDocument();
				newCreatedConfigDoc.setXmlStandalone(true);
				Element newCreatedHudsonRoot = newCreatedConfigDoc.createElement(HUDSON_CONFIG_ROOT);
				newCreatedConfigDoc.appendChild(newCreatedHudsonRoot);

				// loop current hudson configuration and add all the info expect slaves and views to the new created one,
				// add the slaves and views info from old document's slaves and views node
				for (int i = 0; i < currentHudsonRootChildNodes.getLength(); i++) {
					Node child = currentHudsonRootChildNodes.item(i);
					if ("slaves".equals(child.getNodeName())) {
						newCreatedHudsonRoot.appendChild(newCreatedConfigDoc.importNode(oldSlaves, true));
						continue;
					}
					if ("views".equals(child.getNodeName())) {
						newCreatedHudsonRoot.appendChild(newCreatedConfigDoc.importNode(oldViews, true));
						continue;
					}
					newCreatedHudsonRoot.appendChild(newCreatedConfigDoc.importNode(child, true));
				}			

				// output the new created document to replace the current hudson config.xml	file			
				DOMSource domSource = new DOMSource(newCreatedConfigDoc);
				FileOutputStream outputStream=new FileOutputStream(currentConfigXml);
				StreamResult streamResult = new StreamResult(outputStream);
				TransformerFactory transformerFactory = TransformerFactory.newInstance();
				Transformer transformer = transformerFactory.newTransformer();
				transformer.setOutputProperty(OutputKeys.INDENT, "yes");
				transformer.setOutputProperty(OutputKeys.METHOD, "xml");
				transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
				transformer.transform(domSource, streamResult);	
				outputStream.close();
				System.out.println("Migrating slaves and views configuration from old hudson config.xml file succeed");				
			} catch (Exception e) {
				System.out.println("Migrating slaves and views configuration from old hudson config.xml file failed");
			} 
		}else{
			System.out.println("Please make sure the provided old and current hudson config.xml file are all existing ");
		}
	}

}
