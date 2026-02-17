package com.moonlightbox.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * 列表项 DTO，与前端 ListItemModel 及默认 fieldMapping 对应
 * 后端 JSON key: id, title, subtitle, imageUrl, badge, chartType(仅 chart 组件)
 */
@Data
public class ListItemDTO {
    private String id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String badge;
    private String chartType;
    private String period;
    private String unit;
    private List<Map<String, Object>> chartData;
}
