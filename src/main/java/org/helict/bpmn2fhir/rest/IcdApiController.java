package org.helict.bpmn2fhir.rest;

import org.apache.commons.io.IOUtils;
import org.helict.bpmn2fhir.Bpmn2FhirAppProperties;
import org.helict.bpmn2fhir.Bpmn2FhirConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@RestController
public class IcdApiController {

    @Autowired
	 Bpmn2FhirAppProperties properties;

    @GetMapping(value = Bpmn2FhirConfig.ICD_API_TOKEN_BASE_PATH, produces = "application/json")
    public ResponseEntity<?> icdApiToken() {
        try {
            URL icdUrl = new URL(properties.getIcd().getUrl());
            HttpURLConnection con = (HttpURLConnection) icdUrl.openConnection();
            con.setRequestMethod("POST");
            con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            con.setRequestProperty("Authorization", "Basic " + getIcdApiAuth());
            con.setRequestProperty("Accept", "application/json");

            con.setDoOutput(true);
            // post data
            HashMap<String, String> params = new HashMap<>();
            params.put("grant_type", "client_credentials");
            params.put("scope", "icdapi_access");
            String dataString = getParamsString(params);
            // write post data
            try (OutputStream os = con.getOutputStream()) {
                byte[] input = dataString.getBytes(StandardCharsets.UTF_8);
                os.write(input, 0, input.length);
            }

            String result;
            if (con.getResponseCode() > 299) {
                result = IOUtils.toString(con.getErrorStream(), StandardCharsets.UTF_8.name());
            } else {
                result = IOUtils.toString(con.getInputStream(), StandardCharsets.UTF_8.name());
            }

            return new ResponseEntity<>(result, HttpStatus.resolve(con.getResponseCode()));

        } catch (IOException e) {
            e.printStackTrace();
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private static String getParamsString(Map<String, String> params) {
        StringBuilder result = new StringBuilder();

        for (Map.Entry<String, String> entry : params.entrySet()) {
			  try {
				  result.append(URLEncoder.encode(entry.getKey(), StandardCharsets.UTF_8.toString()));
				  result.append("=");
				  result.append(URLEncoder.encode(entry.getValue(), StandardCharsets.UTF_8.toString()));
				  result.append("&");
			  } catch (UnsupportedEncodingException ignored) {}
		  }

        String resultString = result.toString();
        return resultString.length() > 0 ? resultString.substring(0, resultString.length() - 1) : resultString;
    }

    private String getIcdApiAuth() {
        return Base64.getEncoder().encodeToString(
                (properties.getIcd().getClientId() + ":" + properties.getIcd().getClientSecret()).getBytes()
        );
    }

}
