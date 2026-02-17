package com.moonlightbox.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 图表数据明细 - 子表
 */
@Data
@TableName("content_chart_data")
public class ContentChartData {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long chartId;
    private String xLabel;
    private Double yValue;
    private Integer sortOrder;
}
