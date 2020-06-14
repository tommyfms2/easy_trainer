SELECT
    T.ymd_date AS "日付",
    I.store_id AS "ストアID",
    I.parent_code AS "アイテムコード",

    -- 商品系
    item.price AS "[商品系]通常販売価格(税込)",
    -- /商品系

    -- ストア系
    store_daily.store_performance_score AS "[ストア系]ストアパフォーマンススコア",
    -- /ストア系

    -- 商品指定ストアクーポン系
    COALESCE(store_item_coupon.discount_ratio, 0) AS "[商品指定]値引き率",
    -- /商品指定ストアクーポン系

    -- 全品指定ストアクーポン系
    COALESCE(store_all_item_coupon.discount_ratio, 0) AS "[全品指定]値引き率",
    -- /全品指定ストアクーポン系

    -- 全品指定モールクーポン系
    mall_coupon.discount_ratio AS "[モール全品]値引き率",
    -- /全品指定モールクーポン系

    -- マーケティング系
    CASE SUBSTR(CURRENT_DATE, 8, 8)
        WHEN '5' THEN 1
        ELSE 0
    END AS "5のつく日"
    -- /マーケティング系

FROM (SELECT ymd_date FROM shopping.shp_d_calendar WHERE ymd_date BETWEEN '{利用開始日}' AND '{利用終了日}') T
CROSS JOIN (
    SELECT DISTINCT store_id, parent_code
    FROM shopping.shp_f_order_items
    WHERE
        store_id = '{ストアID}' AND
        order_date BETWEEN CONCAT(YEAR(CURRENT_DATE - INTERVAL '1' YEAR), '0101') AND CONCAT(YEAR(CURRENT_DATE), '0101') AND
        cancel_flg IS NULL AND
        isbilling = 1
) I
LEFT JOIN shopping.shp_r_item AS item ON (
    I.store_id = item.store_id AND
    I.parent_code = item.item_code
)  -- 商品データ
LEFT JOIN (
    SELECT top 1 *
    FROM shopping.shp_f_store_daily
    WHERE store_id = '{ストアID}'
    ORDER BY log_date DESC
    ) AS store_daily ON (
    I.store_id = store_daily.store_id
)  -- 日毎ストアデータ
LEFT JOIN (
    SELECT
        T.ymd_date,
        C.store_id,
        C.item_id,
        AVG(COALESCE(C.order_count_cond, 0)) AS order_count_cond,
        AVG(COALESCE(C.order_price_cond, 0)) AS order_price_cond,
        AVG(COALESCE(C.discount_price, 0)) AS discount_price,
        AVG(COALESCE(C.discount_ratio, 0)) AS discount_ratio,
        AVG(C.all_use_num) AS all_use_num
    FROM (SELECT ymd_date FROM shopping.shp_d_calendar WHERE ymd_date BETWEEN '{利用開始日}' AND '{利用終了日}') T
    CROSS JOIN (
        SELECT target_item.item_id, coupon.*
        FROM shopping.shp_d_coupon_target_item AS target_item
        LEFT JOIN shopping.shp_d_coupon AS coupon ON (
            target_item.coupon_id = coupon.coupon_id
        )
        WHERE
            coupon.mallcoupon_flag = 0 AND  -- ストアクーポン
            coupon_public_type > 0 AND  -- クーポン一覧画面に公開または獲得制限
            thank_you_flag = 0 AND  -- サンキュークーポンじゃない
            n_day_flag = 0 AND  -- N日クーポンではない
            coupon_type <> 3  -- 商品指定
    ) C
    WHERE
        C.use_start_time <= T.ymd_date AND
        T.ymd_date <= C.use_end_time
    GROUP BY T.ymd_date, C.store_id, C.item_id
) AS store_item_coupon ON (
    T.ymd_date = store_item_coupon.ymd_date AND
    I.store_id = store_item_coupon.store_id AND
    I.parent_code = store_item_coupon.item_id
)  -- 商品指定ストアクーポン
LEFT JOIN (
    SELECT
        T.ymd_date,
        C.store_id,
        AVG(COALESCE(C.order_count_cond, 0)) AS order_count_cond,
        AVG(COALESCE(C.order_price_cond, 0)) AS order_price_cond,
        AVG(COALESCE(C.discount_price, 0)) AS discount_price,
        AVG(COALESCE(C.discount_ratio, 0)) AS discount_ratio,
        AVG(C.all_use_num) AS all_use_num
    FROM (SELECT ymd_date FROM shopping.shp_d_calendar WHERE ymd_date BETWEEN '{利用開始日}' AND '{利用終了日}') T
    CROSS JOIN (
        SELECT coupon.*
        FROM shopping.shp_d_coupon AS coupon
        WHERE
            mallcoupon_flag = 0 AND  -- ストアクーポン
            coupon_public_type > 0 AND  -- クーポン一覧画面に公開または獲得制限
            thank_you_flag = 0 AND  -- サンキュークーポンじゃない
            n_day_flag = 0 AND  -- N日クーポンではない
            coupon_type = 3 -- 全商品指定
    ) C
    WHERE
        C.use_start_time <= T.ymd_date AND
        T.ymd_date <= C.use_end_time
    GROUP BY T.ymd_date, C.store_id
) AS store_all_item_coupon ON (
    T.ymd_date = store_all_item_coupon.ymd_date AND
    I.store_id = store_all_item_coupon.store_id
)  -- 全品指定ストアクーポン
LEFT JOIN (
    SELECT
        T.ymd_date,
        AVG(COALESCE(C.order_count_cond, 0)) AS order_count_cond,
        AVG(COALESCE(C.order_price_cond, 0)) AS order_price_cond,
        AVG(COALESCE(C.discount_price, 0)) AS discount_price,
        AVG(COALESCE(C.discount_ratio, 0)) AS discount_ratio,
        AVG(C.all_use_num) AS all_use_num
    FROM (SELECT ymd_date FROM shopping.shp_d_calendar WHERE ymd_date BETWEEN '{利用開始日}' AND '{利用終了日}') T
    CROSS JOIN (
        SELECT * FROM shopping.shp_d_coupon
        WHERE
            mallcoupon_flag = 1 AND
            coupon_assort_type = 1 AND
            coupon_public_type > 0 AND  -- クーポン一覧画面に公開または獲得制限
            thank_you_flag = 0 AND  -- サンキュークーポンじゃない
            n_day_flag = 0 -- N日クーポンではない
    ) C
    WHERE
        C.use_start_time <= T.ymd_date AND
        T.ymd_date <= C.use_end_time
    GROUP BY T.ymd_date
) AS mall_coupon ON (
    T.ymd_date = mall_coupon.ymd_date
) -- モール全品モールクーポン
;