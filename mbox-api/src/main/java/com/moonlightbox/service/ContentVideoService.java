package com.moonlightbox.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.moonlightbox.dto.VideoListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.dto.VideoDetailDTO;
import com.moonlightbox.entity.ContentVideo;
import com.moonlightbox.mapper.ContentVideoMapper;
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

    public PageResult<VideoListItemDTO> list(int page, int size) {
        int p = Math.max(1, page);
        int s = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, 100);
        Page<ContentVideo> pageReq = new Page<>(p, s);
        Page<ContentVideo> result = contentVideoMapper.selectPage(pageReq,
                new LambdaQueryWrapper<ContentVideo>().orderByDesc(ContentVideo::getCreatedAt));
        List<VideoListItemDTO> list = result.getRecords().stream().map(this::toListItem).collect(Collectors.toList());
        return new PageResult<>(list, result.getTotal(), (int) result.getCurrent(), (int) result.getSize());
    }

    public VideoDetailDTO getDetail(String id) {
        Long pk = IdParseUtil.parseId(id);
        if (pk == null)
            return null;
        ContentVideo one = contentVideoMapper.selectById(pk);
        if (one == null)
            return null;
        return toDetailItem(one);
    }

    private VideoListItemDTO toListItem(ContentVideo e) {
        VideoListItemDTO dto = new VideoListItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setImageUrl(e.getImageUrl());
        dto.setBadge(e.getBadge());
        return dto;
    }

    private VideoDetailDTO toDetailItem(ContentVideo e) {
        VideoDetailDTO dto = new VideoDetailDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setImageUrl(e.getImageUrl());
        dto.setBadge(e.getBadge());
        dto.setContent(e.getContent());
        dto.setMediaUrl(e.getMediaUrl());
        dto.setDuration(e.getDuration());
        dto.setResolution(e.getResolution());
        dto.setAuthor(e.getAuthor());
        return dto;
    }
}
