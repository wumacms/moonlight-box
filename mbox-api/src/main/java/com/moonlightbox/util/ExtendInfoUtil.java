package com.moonlightbox.util;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 将 DB 中的 extendInfo 字符串（JSON）解析为 Map&lt;String, String&gt;，与前端 extendInfo 协议一致
 */
public final class ExtendInfoUtil {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static Map<String, String> parse(String extendInfo) {
        Map<String, Object> parsed = parseObject(extendInfo);
        if (parsed.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<String, String> out = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entry : parsed.entrySet()) {
            Object value = entry.getValue();
            if (value == null) continue;
            if (value instanceof String || value instanceof Number || value instanceof Boolean) {
                out.put(entry.getKey(), String.valueOf(value));
            }
        }
        return out;
    }

    public static Map<String, Object> parseObject(String extendInfo) {
        if (extendInfo == null || extendInfo.isBlank()) {
            return Collections.emptyMap();
        }
        try {
            return MAPPER.readValue(extendInfo, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            return Collections.emptyMap();
        }
    }
}
