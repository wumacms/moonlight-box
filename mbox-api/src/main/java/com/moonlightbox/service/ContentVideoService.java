package com.moonlightbox.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.moonlightbox.dto.DetailItemDTO;
import com.moonlightbox.dto.ListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.entity.ContentVideo;
import com.moonlightbox.mapper.ContentVideoMapper;
import com.moonlightbox.util.ExtendInfoUtil;
import com.moonlightbox.util.IdParseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContentVideoService {

    private static final int DEFAULT_PAGE_SIZE = 10;

    private final ContentVideoMapper contentVideoMapper;

    public PageResult<ListItemDTO> list(int page, int size) {
        int p = Math.max(1, page);
        int s = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, 100);
        Page<ContentVideo> pageReq = new Page<>(p, s);
        Page<ContentVideo> result = contentVideoMapper.selectPage(pageReq,
                new LambdaQueryWrapper<ContentVideo>().orderByDesc(ContentVideo::getCreatedAt));
        List<ListItemDTO> list = result.getRecords().stream().map(this::toListItem).collect(Collectors.toList());
        return new PageResult<>(list, result.getTotal(), (int) result.getCurrent(), (int) result.getSize());
    }

    public DetailItemDTO getDetail(String id) {
        Long pk = IdParseUtil.parseId(id);
        if (pk == null) return null;
        ContentVideo one = contentVideoMapper.selectById(pk);
        if (one == null) return null;
        return toDetailItem(one);
    }

    private ListItemDTO toListItem(ContentVideo e) {
        ListItemDTO dto = new ListItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setImageUrl(e.getImageUrl());
        dto.setBadge(e.getBadge());
        return dto;
    }

    private DetailItemDTO toDetailItem(ContentVideo e) {
        DetailItemDTO dto = new DetailItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setContent(e.getContent());
        dto.setMediaUrl(e.getMediaUrl());
        dto.setExtendInfo(ExtendInfoUtil.parse(e.getExtendInfo()));
        return dto;
    }
}
