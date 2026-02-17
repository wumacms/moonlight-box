package com.moonlightbox.controller;

import com.moonlightbox.common.ApiResponse;
import com.moonlightbox.dto.ChartDetailDTO;
import com.moonlightbox.dto.ListItemDTO;
import com.moonlightbox.dto.PageResult;
import com.moonlightbox.service.ContentChartService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 图表组件 API：列表（分页）+ 详情
 */
@RestController
@RequestMapping("/api/chart")
@RequiredArgsConstructor
public class ChartController {

    private final ContentChartService contentChartService;

    @GetMapping("/list")
    public ApiResponse<PageResult<ListItemDTO>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.ok(contentChartService.list(page, size));
    }

    @GetMapping("/detail")
    public ResponseEntity<ApiResponse<ChartDetailDTO>> detail(@RequestParam String id) {
        ChartDetailDTO detail = contentChartService.getDetail(id);
        if (detail == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiResponse.fail(404, null));
        }
        return ResponseEntity.ok(ApiResponse.ok(detail));
    }
}
