package com.mottu.motolocation.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    // PASSO 1: O codificador de senhas continua aqui. Ele é essencial.
    @Bean
    public PasswordEncoder passwordEncoder() {
        // Usamos BCrypt para criptografar as senhas de forma segura.
        return new BCryptPasswordEncoder();
    }

    // PASSO 2: O método userDetailsService() foi REMOVIDO.
    // O Spring agora vai usar automaticamente a nossa classe AppUserDetailsService
    // porque ela implementa a interface UserDetailsService e está marcada com @Service.

    // PASSO 3: As regras de segurança continuam as mesmas.
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Desabilitar CSRF para simplificar, especialmente para a API
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(authorize -> authorize
                        // Rotas públicas (login, css, js)
                        .requestMatchers("/login", "/", "/css/**", "/js/**").permitAll()

                        // Rotas da APLICAÇÃO WEB que exigem perfil ADMIN
                        .requestMatchers("/web/motos/new", "/web/motos/edit/**", "/web/motos/delete/**").hasRole("ADMIN")

                        // Permitir que qualquer usuário autenticado acesse a lista de motos web
                        .requestMatchers("/web/**").authenticated()

                        // DEIXAR A API REST PÚBLICA (fora do escopo da segurança de formulário)
                        .requestMatchers("/motos/**", "/sensores/**", "/movimentacoes/**").permitAll()

                        // Qualquer outra requisição deve ser autenticada
                        .anyRequest().authenticated()
                )
                .formLogin(form -> form
                        .loginPage("/login")
                        .defaultSuccessUrl("/web/motos", true) // Redireciona para a lista após o login
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutSuccessUrl("/login?logout") // Redireciona para o login com msg de logout
                        .permitAll()
                );

        return http.build();
    }
}