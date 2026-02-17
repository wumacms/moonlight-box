package com.moonlightbox.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 图表组件 - 主表
 */
@Data
@TableName("content_chart")
public class ContentChart {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String title;
    private String subtitle;
    private String chartType;
    private String period;
    private String unit;
    private LocalDateTime createdAt;
}
