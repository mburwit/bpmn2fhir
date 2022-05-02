package org.helict.bpmn2fhir;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@ConfigurationProperties(prefix = "bpmn2fhir")
public class Bpmn2FhirAppProperties {
    private ICD icd;

    public ICD getIcd() {
        return icd;
    }

    public void setIcd(ICD icd) {
        this.icd = icd;
    }

    public static class ICD {
        private String url;
        private String clientId;
        private String clientSecret;

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }

        public String getClientId() {
            return clientId;
        }

        public void setClientId(String clientId) {
            this.clientId = clientId;
        }

        public String getClientSecret() {
            return clientSecret;
        }

        public void setClientSecret(String clientSecret) {
            this.clientSecret = clientSecret;
        }
    }
}
