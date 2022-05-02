package org.helict.bpmn2fhir.transform;

import net.sf.saxon.s9api.*;

import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.logging.Logger;

public class Bpmn2FhirTransformer {

    private final Logger logger = Logger.getLogger(Bpmn2FhirTransformer.class.getName());
    private static final Bpmn2FhirTransformer instance = new Bpmn2FhirTransformer();

    private final Processor processor;
    private final Xslt30Transformer transformer;

    private Bpmn2FhirTransformer() {
        this.processor = new Processor(false);
        try {
            this.transformer = initXslTransformer();
        } catch (SaxonApiException e) {
            throw new InternalError(e);
        }
    }

    private Xslt30Transformer initXslTransformer() throws SaxonApiException {
        XsltCompiler compiler = processor.newXsltCompiler();
        XsltExecutable stylesheet;
        InputStream inputStream = getClass()
                .getClassLoader().getResourceAsStream("xsl/bpmn2fhir.xsl");
        stylesheet = compiler.compile(new StreamSource(inputStream));
        logger.info("XSL stylesheet successfully compiled!");
        return stylesheet.load30();
    }

    public static Bpmn2FhirTransformer getInstance() {
        return instance;
    }

    public String transform(InputStream bpmnXml) throws SaxonApiException {
        logger.info("Invoking XSL transformation...");
        Source source = new StreamSource(bpmnXml);
        StringWriter outWriter = new StringWriter();
        Destination destination = processor.newSerializer(outWriter);
        logger.info("Starting transformation...");
        transformer.transform(source, destination);
        logger.info("Transformation finished!");
        return outWriter.getBuffer().toString();
    }

    public String transform(String bpmnXml) throws SaxonApiException {
        InputStream inputStream = new ByteArrayInputStream(bpmnXml.getBytes());
        return transform(inputStream);
    }
}
