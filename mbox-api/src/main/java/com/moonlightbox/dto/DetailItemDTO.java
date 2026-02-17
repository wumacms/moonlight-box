package com.moonlightbox.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.Map;

/**
 * 详情 DTO，与前端 DetailItemModel 协议一致
 */
@Data
public class DetailItemDTO {
    private String id;
    private String title;
    private String content;
    private String mediaUrl;
    @JsonProperty("extendInfo")
    private Map<String, String> extendInfo;
}
