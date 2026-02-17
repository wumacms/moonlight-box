package com.moonlightbox.dto;

import lombok.Data;

/**
 * 视频详情 DTO
 */
@Data
public class VideoDetailDTO {
    private String id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String badge;
    private String content;
    private String mediaUrl;
    private String duration;
    private String resolution;
    private String author;
}
