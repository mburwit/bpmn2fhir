package org.helict.bpmn2fhir.rest;

import ca.uhn.fhir.context.FhirContext;
import net.sf.saxon.s9api.SaxonApiException;
import org.apache.commons.io.IOUtils;
import org.helict.bpmn2fhir.Bpmn2FhirConfig;
import org.helict.bpmn2fhir.transform.Bpmn2FhirTransformer;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@RestController
public class Bpmn2FhirController {

    @PostMapping(value = Bpmn2FhirConfig.BPMN_2_FHIR_BASE_PATH, consumes="application/xml", produces = "application/fhir+json")
    protected ResponseEntity<?> bpmn2Fhir(@RequestBody String payload) {
        //Change the URL with any other publicly accessible POST resource, which accepts JSON request body
        try {
            InputStream payloadStream =
                    IOUtils.toInputStream(payload, StandardCharsets.UTF_8);
            String result = Bpmn2FhirTransformer.getInstance().transform(payloadStream);
            result = FhirContext.forR4().newJsonParser().encodeResourceToString(FhirContext.forR4().newXmlParser().parseResource(result));
            return new ResponseEntity<>(result, HttpStatus.OK);
        } catch (SaxonApiException e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

}
