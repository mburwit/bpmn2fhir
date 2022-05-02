package org.helict.fhir.jpa.starter.security;

import ca.uhn.fhir.jpa.starter.BaseJpaRestfulServer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.thymeleaf.extras.springsecurity5.dialect.SpringSecurityDialect;
import org.thymeleaf.spring5.SpringTemplateEngine;

@Configuration
public class ThymeleafSecurityMvcConfig {
	private static final org.slf4j.Logger ourLog = org.slf4j.LoggerFactory.getLogger(BaseJpaRestfulServer.class);

	@Autowired
	private SpringSecurityDialect sec;

	@Autowired
	private SpringTemplateEngine templateEngine;

	@Bean
	public SpringTemplateEngine myTemplateEngine() {
		if (this.sec != null) {
			ourLog.info("Enable use of 'sec' in Thymeleaf templates");
			this.templateEngine.addDialect(sec); // Enable use of "sec"
		} else {
			ourLog.info("No 'sec' available!");
		}
		return this.templateEngine;
	}
}
