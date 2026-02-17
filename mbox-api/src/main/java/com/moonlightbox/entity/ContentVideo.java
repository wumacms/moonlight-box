package com.moonlightbox.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 视频组件 - 视频列表与详情（mediaUrl 为视频链接）
 */
@Data
@TableName("content_video")
public class ContentVideo {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String badge;
    private String content;
    private String mediaUrl;
    private String extendInfo;
    private LocalDateTime createdAt;
}
