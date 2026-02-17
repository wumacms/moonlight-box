package com.moonlightbox.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 卡片组件 - 文章/卡片列表与详情
 */
@Data
@TableName("content_card")
public class ContentCard {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String badge;
    private String content;
    private String mediaUrl;
    private String author;
    private String pubDate;
    private String category;
    private LocalDateTime createdAt;
}
