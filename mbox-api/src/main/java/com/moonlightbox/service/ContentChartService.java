package com.moonlightbox.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.moonlightbox.dto.DetailItemDTO;
import com.moonlightbox.dto.ListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.entity.ContentChart;
import com.moonlightbox.mapper.ContentChartMapper;
import com.moonlightbox.util.ExtendInfoUtil;
import com.moonlightbox.util.IdParseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContentChartService {

    private static final int DEFAULT_PAGE_SIZE = 10;

    private final ContentChartMapper contentChartMapper;

    public PageResult<ListItemDTO> list(int page, int size) {
        int p = Math.max(1, page);
        int s = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, 100);
        Page<ContentChart> pageReq = new Page<>(p, s);
        Page<ContentChart> result = contentChartMapper.selectPage(pageReq,
                new LambdaQueryWrapper<ContentChart>().orderByDesc(ContentChart::getCreatedAt));
        List<ListItemDTO> list = result.getRecords().stream().map(this::toListItem).collect(Collectors.toList());
        return new PageResult<>(list, result.getTotal(), (int) result.getCurrent(), (int) result.getSize());
    }

    public DetailItemDTO getDetail(String id) {
        Long pk = IdParseUtil.parseId(id);
        if (pk == null) return null;
        ContentChart one = contentChartMapper.selectById(pk);
        if (one == null) return null;
        return toDetailItem(one);
    }

    private ListItemDTO toListItem(ContentChart e) {
        ListItemDTO dto = new ListItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setImageUrl(e.getImageUrl());
        dto.setBadge(e.getBadge());
        Map<String, Object> extendInfo = ExtendInfoUtil.parseObject(e.getExtendInfo());
        dto.setChartType(stringValue(extendInfo.get("chartType")));
        dto.setPeriod(stringValue(extendInfo.get("period")));
        dto.setUnit(stringValue(extendInfo.get("unit")));
        dto.setChartData(castChartData(extendInfo.get("chartData")));
        return dto;
    }

    private DetailItemDTO toDetailItem(ContentChart e) {
        DetailItemDTO dto = new DetailItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setContent(e.getContent());
        dto.setMediaUrl(e.getMediaUrl());
        dto.setExtendInfo(ExtendInfoUtil.parse(e.getExtendInfo()));
        return dto;
    }

    private String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> castChartData(Object value) {
        if (value instanceof List<?>) {
            List<?> list = (List<?>) value;
            if (list.stream().allMatch(item -> item instanceof Map)) {
                return (List<Map<String, Object>>) value;
            }
        }
        return Collections.emptyList();
    }
}
