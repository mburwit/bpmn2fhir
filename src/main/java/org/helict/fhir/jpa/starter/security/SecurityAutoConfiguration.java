package org.helict.fhir.jpa.starter.security;

import ca.uhn.fhir.jpa.starter.BaseJpaRestfulServer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.AutoConfigureAfter;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.thymeleaf.extras.springsecurity5.dialect.SpringSecurityDialect;
import org.thymeleaf.spring5.SpringTemplateEngine;
import org.thymeleaf.spring5.templateresolver.SpringResourceTemplateResolver;
import org.thymeleaf.templateresolver.ITemplateResolver;

/**
 * {@link EnableAutoConfiguration Auto-configuration} for HAPI FHIR.
 *
 */
@Configuration
@AutoConfigureAfter({ KeycloakSecurityConfig.class })
@Import({ KeycloakSecurityConfig.class, DisableSecurityConfig.class, ThymeleafSecurityMvcConfig.class })
public class SecurityAutoConfiguration {
}