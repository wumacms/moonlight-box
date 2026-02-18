package com.moonlightbox.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.moonlightbox.dto.CardDetailDTO;
import com.moonlightbox.dto.CardListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.entity.ContentCard;
import com.moonlightbox.mapper.ContentCardMapper;
import com.moonlightbox.util.IdParseUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContentCardService {

    private static final int DEFAULT_PAGE_SIZE = 10;

    private final ContentCardMapper contentCardMapper;

    public PageResult<CardListItemDTO> list(int page, int size) {
        int p = Math.max(1, page);
        int s = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, 100);
        Page<ContentCard> pageReq = new Page<>(p, s);
        Page<ContentCard> result = contentCardMapper.selectPage(pageReq,
                new LambdaQueryWrapper<ContentCard>().orderByDesc(ContentCard::getCreatedAt));
        List<CardListItemDTO> list = result.getRecords().stream().map(this::toListItem).collect(Collectors.toList());
        return new PageResult<>(list, result.getTotal(), (int) result.getCurrent(), (int) result.getSize());
    }

    public CardDetailDTO getDetail(String id) {
        Long pk = IdParseUtil.parseId(id);
        if (pk == null)
            return null;
        ContentCard one = contentCardMapper.selectById(pk);
        if (one == null)
            return null;
        return toDetailItem(one);
    }

    private CardListItemDTO toListItem(ContentCard e) {
        CardListItemDTO dto = new CardListItemDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setImageUrl(e.getImageUrl());
        dto.setBadge(e.getBadge());
        return dto;
    }

    private CardDetailDTO toDetailItem(ContentCard e) {
        CardDetailDTO dto = new CardDetailDTO();
        dto.setId(String.valueOf(e.getId()));
        dto.setTitle(e.getTitle());
        dto.setSubtitle(e.getSubtitle());
        dto.setImageUrl(e.getImageUrl());
        dto.setBadge(e.getBadge());
        dto.setContent(e.getContent());
        dto.setMediaUrl(e.getMediaUrl());
        dto.setAuthor(e.getAuthor());
        dto.setPubDate(e.getPubDate());
        dto.setCategory(e.getCategory());
        return dto;
    }
}
