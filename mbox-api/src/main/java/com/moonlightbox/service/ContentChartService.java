package com.moonlightbox.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.moonlightbox.dto.ChartDetailDTO;
import com.moonlightbox.dto.ListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.entity.ContentChart;
import com.moonlightbox.entity.ContentChartData;
import com.moonlightbox.mapper.ContentChartDataMapper;
import com.moonlightbox.mapper.ContentChartMapper;
import com.moonlightbox.util.IdParseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContentChartService {

    private static final int DEFAULT_PAGE_SIZE = 10;

    private final ContentChartMapper contentChartMapper;
    private final ContentChartDataMapper contentChartDataMapper;

    public PageResult<ListItemDTO> list(int page, int size) {
        int p = Math.max(1, page);
        int s = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, 100);
        Page<ContentChart> pageReq = new Page<>(p, s);
        Page<ContentChart> result = contentChartMapper.selectPage(pageReq,
                new LambdaQueryWrapper<ContentChart>().orderByDesc(ContentChart::getCreatedAt));
        List<ListItemDTO> list = result.getRecords().stream().map(this::toListItem).collect(Collectors.toList());
        return new PageResult<>(list, result.getTotal(), (int) result.getCurrent(), (int) result.getSize());
    }

    public ChartDetailDTO getDetail(String id) {
        Long pk = IdParseUtil.parseId(id);
        if (pk == null)
            return null;
        ContentChart one = contentChartMapper.selectById(pk);
        if (one == null)
            return null;
        return toDetailItem(one);
    }

    private ListItemDTO toListItem(ContentChart e) {
        ListItemDTO dto = new ListItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setChartType(e.getChartType());
        dto.setPeriod(e.getPeriod());
        dto.setUnit(e.getUnit());

        // 查询子表数据
        List<ContentChartData> dataList = contentChartDataMapper.selectList(
                new LambdaQueryWrapper<ContentChartData>()
                        .eq(ContentChartData::getChartId, e.getId())
                        .orderByAsc(ContentChartData::getSortOrder));

        dto.setChartData(dataList.stream().map(d -> {
            Map<String, Object> map = new java.util.HashMap<>();
            map.put("x", d.getXLabel());
            map.put("y", d.getYValue());
            return map;
        }).collect(Collectors.toList()));

        return dto;
    }

    private ChartDetailDTO toDetailItem(ContentChart e) {
        ChartDetailDTO dto = new ChartDetailDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setChartType(e.getChartType());
        dto.setPeriod(e.getPeriod());
        dto.setUnit(e.getUnit());

        List<ContentChartData> dataList = contentChartDataMapper.selectList(
                new LambdaQueryWrapper<ContentChartData>()
                        .eq(ContentChartData::getChartId, e.getId())
                        .orderByAsc(ContentChartData::getSortOrder));
        dto.setChartData(dataList.stream().map(d -> {
            Map<String, Object> map = new java.util.HashMap<>();
            map.put("x", d.getXLabel());
            map.put("y", d.getYValue());
            return map;
        }).collect(Collectors.toList()));

        return dto;
    }
}
