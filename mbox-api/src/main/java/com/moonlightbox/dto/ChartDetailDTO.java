package com.moonlightbox.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * 图表详情 DTO
 */
@Data
public class ChartDetailDTO {
    private String id;
    private String title;
    private String subtitle;
    private String chartType;
    private String period;
    private String unit;
    private List<Map<String, Object>> chartData;
}
