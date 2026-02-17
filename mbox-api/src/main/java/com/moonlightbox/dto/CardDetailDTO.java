package com.moonlightbox.dto;

import lombok.Data;

/**
 * 卡片详情 DTO
 */
@Data
public class CardDetailDTO {
    private String id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String badge;
    private String content;
    private String mediaUrl;
    private String author;
    private String pubDate;
    private String category;
}
