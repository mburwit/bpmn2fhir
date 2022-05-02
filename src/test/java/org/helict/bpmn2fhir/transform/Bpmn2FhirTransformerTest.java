package org.helict.bpmn2fhir.transform;

import net.sf.saxon.s9api.SaxonApiException;
import org.junit.jupiter.api.Test;

import java.io.InputStream;

class Bpmn2FhirTransformerTest {

	@Test
	public void testTransform() throws SaxonApiException {
		InputStream inputStream = getClass()
			.getClassLoader().getResourceAsStream("bpmn2fhir/diagram.xml");
		System.out.println(Bpmn2FhirTransformer.getInstance().transform(
			inputStream
		));
	}
}