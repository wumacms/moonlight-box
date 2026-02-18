package com.moonlightbox.dto;

import lombok.Data;

@Data
public class CardListItemDTO {
    private String id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String badge;
}
