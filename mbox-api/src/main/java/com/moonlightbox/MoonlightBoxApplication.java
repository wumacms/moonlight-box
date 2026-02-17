package com.moonlightbox;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.moonlightbox.mapper")
public class MoonlightBoxApplication {

    public static void main(String[] args) {
        SpringApplication.run(MoonlightBoxApplication.class, args);
    }
}
