package com.moonlightbox.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class ChartListItemDTO {
    private String id;
    private String title;
    private String subtitle;
    private String chartType;
    private String period;
    private String unit;
    private List<Map<String, Object>> chartData;
}
