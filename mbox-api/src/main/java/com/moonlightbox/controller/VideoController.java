package com.moonlightbox.controller;

import com.moonlightbox.common.ApiResponse;
import com.moonlightbox.dto.ListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.dto.VideoDetailDTO;
import com.moonlightbox.service.ContentVideoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 视频组件 API：列表（分页）+ 详情
 */
@RestController
@RequestMapping("/api/video")
@RequiredArgsConstructor
public class VideoController {

    private final ContentVideoService contentVideoService;

    @GetMapping("/list")
    public ApiResponse<PageResult<ListItemDTO>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(contentVideoService.list(page, size));
    }

    @GetMapping("/detail")
    public ResponseEntity<ApiResponse<VideoDetailDTO>> detail(@RequestParam String id) {
        VideoDetailDTO detail = contentVideoService.getDetail(id);
        if (detail == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.fail(404, null));
        }
        return ResponseEntity.ok(ApiResponse.ok(detail));
    }
}
