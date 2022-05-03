package org.helict.bpmn2fhir;

import ca.uhn.fhir.jpa.starter.AppProperties;
import org.slf4j.Logger;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableConfigurationProperties(Bpmn2FhirAppProperties.class)
@ComponentScan(basePackages = "org.helict.bpmn2fhir")
public class Bpmn2FhirConfig {

	public static final String BPMN_2_FHIR_BASE_PATH = "/bpmn2fhir";
	public static final String ICD_API_TOKEN_BASE_PATH = "/icd-api-token";
	private static final Logger ourLog = org.slf4j.LoggerFactory.getLogger(Bpmn2FhirConfig.class);

	@Bean
	public WebMvcConfigurer corsConfigurer(AppProperties appProperties) {
		return new WebMvcConfigurer() {
			@Override
			public void addCorsMappings(CorsRegistry registry) {
				String[] allAllowedCORSOrigins = appProperties.getCors().getAllowed_origin().toArray(new String[0]);
				ourLog.info("Applying global CORS config. Allowed Origins: {}", (Object[]) allAllowedCORSOrigins);
				registry.addMapping(BPMN_2_FHIR_BASE_PATH).allowedOriginPatterns(allAllowedCORSOrigins);
				registry.addMapping(ICD_API_TOKEN_BASE_PATH).allowedOriginPatterns(allAllowedCORSOrigins);
			}
		};
	}
}
