package com.moonlightbox.util;

/**
 * 安全解析详情接口的 id 参数（可能为 "1,1" 等，取第一个数字）
 */
public final class IdParseUtil {

    /**
     * 解析 id 为 Long。若为 "1,1" 则取 "1"；若无法解析则返回 null。
     */
    public static Long parseId(String id) {
        if (id == null || id.isBlank()) return null;
        String first = id.trim().split(",")[0].trim();
        if (first.isEmpty()) return null;
        try {
            return Long.parseLong(first);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
