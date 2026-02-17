package com.moonlightbox.controller;

import com.moonlightbox.common.ApiResponse;
import com.moonlightbox.dto.CardDetailDTO;
import com.moonlightbox.dto.ListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.service.ContentCardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 卡片组件 API：列表（分页）+ 详情
 */
@RestController
@RequestMapping("/api/card")
@RequiredArgsConstructor
public class CardController {

    private final ContentCardService contentCardService;

    @GetMapping("/list")
    public ApiResponse<PageResult<ListItemDTO>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(contentCardService.list(page, size));
    }

    @GetMapping("/detail")
    public ResponseEntity<ApiResponse<CardDetailDTO>> detail(@RequestParam String id) {
        CardDetailDTO detail = contentCardService.getDetail(id);
        if (detail == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.fail(404, null));
        }
        return ResponseEntity.ok(ApiResponse.ok(detail));
    }
}
