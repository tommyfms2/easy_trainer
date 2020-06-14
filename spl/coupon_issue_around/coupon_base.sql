
select
	T.ymd_date as ymd_date,
	T.day_of_week as day_of_week,
	-- ストア条件
	T.store_id as store_id,
	T.long_catalog_name as long_catalog_name,
	T.mrating_excellent as mrating_excellent,
	T.mrating_good as mrating_good,
	T.mrating_ok as mrating_ok,
	T.mrating_bad as mrating_bad,
	T.mrating_awful as mrating_awful,
	T.best_store as best_store,
	T.store_introduction as store_introduction,
	T.store_category1 as store_category1,
	T.store_category2 as store_category2,
	T.store_category3 as store_category3,
	T.store_review_rate as store_review_rate,
	T.pmall_status as pmall_status,
	-- 商品条件
	T.item_id as item_id,
	T.discount_rate as discount_rate,
	T.item_type as item_type,
    T.item_name as item_name,
    T.original_price as original_price, -- メーカー希望価格
    T.price as price, -- 通常価格
    T.headline as headline,
    T.delivery_type as delivery_type,
    T.spec1 as spec1,
    T.spec2 as spec2,
    T.spec3 as spec3,
    T.spec4 as spec4,
    T.spec5 as spec5,
    T.spec6 as spec6,
    T.spec7 as spec7,
    T.spec8 as spec8,
    T.spec9 as spec9,
    T.show_stock_type as show_stock_type,
    T.final_pr_rate as final_pr_rate,
    T.brand_id as brand_id,
    T.jan_code as jan_code,
    T.y_shopping_display_flag as y_shopping_display_flag,
    count(case when T.store_id=out_wish.store_id and T.item_id=out_wish.item_code and out_wish.create_time < CAST(T.ymd_date as DATE FORMAT 'YYYYMMDD') and (out_wish.temp_delete_flag=0 or out_wish.temp_delete_time > CAST(T.ymd_date as DATE FORMAT 'YYYYMMDD')) then out_wish.item_code else null end) as wish_count,
    T.coupon_title as coupon_title,
	T.coupon_description as coupon_description,
    T.use_start_time as use_start_time,
    T.quantity as quantity

FROM
(
	select
	base.ymd_date as ymd_date,
	base.day_of_week as day_of_week,
	-- ストア条件
	d_store_hist.store_account as store_id,
	d_store_hist.long_catalog_name as long_catalog_name,
	d_store_hist.mrating_excellent as mrating_excellent,
	d_store_hist.mrating_good as mrating_good,
	d_store_hist.mrating_ok as mrating_ok,
	d_store_hist.mrating_bad as mrating_bad,
	d_store_hist.mrating_awful as mrating_awful,
	d_store_hist.best_store as best_store,
	d_store_hist.store_introduction as store_introduction,
	d_store_hist.store_category1 as store_category1,
	d_store_hist.store_category2 as store_category2,
	d_store_hist.store_category3 as store_category3,
	d_store_hist.store_review_rate as store_review_rate,
	d_store_hist.pmall_status as pmall_status,
	-- 商品条件
	base.item_id as item_id,
	(case when base.ymd_date < base.use_start_time  then 0 else base.discount_rate end) as discount_rate,
	r_item.item_type as item_type,
    r_item.item_name as item_name,
    r_item.original_price as original_price, -- メーカー希望価格
    r_item.price as price, -- 通常価格
    r_item.headline as headline,
    r_item.delivery_type as delivery_type,
    r_item.spec1 as spec1,
    r_item.spec1 as spec2,
    r_item.spec1 as spec3,
    r_item.spec1 as spec4,
    r_item.spec1 as spec5,
    r_item.spec1 as spec6,
    r_item.spec1 as spec7,
    r_item.spec1 as spec8,
    r_item.spec1 as spec9,
    r_item.show_stock_type as show_stock_type,
    r_item.final_pr_rate as final_pr_rate,
    r_item.predict_brand_id as brand_id,
    r_item.total_jan_code as jan_code,
    r_item.y_shopping_display_flag as y_shopping_display_flag,
    -- クーポン条件
    base.coupon_title as coupon_title,
	base.coupon_description as coupon_description,
    base.use_start_time as use_start_time,
    -- 販売数
    (case when f_order_items.quantity is null then 0 else f_order_items.quantity end) as quantity
from
	(
	select
	  d_calendar.YMD_DATE as ymd_date,
	  d_calendar.DAY_OF_WEEK as day_of_week,
	  outer_d_coupon.coupon_id as coupon_id,
	  outer_d_coupon.coupon_title as coupon_title,
	  outer_d_coupon.coupon_description as coupon_description,
	  outer_d_coupon.use_start_time as use_start_time,
	  outer_d_coupon.discount_rate as discount_rate,
	  d_coupon_target.item_id as item_id
	from
	  shopping.shp_d_coupon_target_item as d_coupon_target
	inner join
	    (
		select
		  d_coupon.coupon_id as coupon_id,
		  d_coupon.coupon_title as coupon_title,
		  d_coupon.coupon_description as coupon_description,
		  d_coupon.use_start_time as use_start_time,
		  d_coupon.discount_ratio as discount_rate
		FROM
		  shopping.shp_d_coupon as d_coupon
		WHERE
		  d_coupon.r8_flag = 0 AND --rooクーポンじゃない
		  d_coupon.mallcoupon_flag = 0 AND --ストアクーポン
		  d_coupon.thank_you_flag = 0 AND --サンキュークーポンじゃない
		  d_coupon.n_day_flag = 0 AND --n日クーポンでない
		  d_coupon.order_price_cond is null AND -- 金額条件がない
		  d_coupon.order_count_cond is null AND -- 個数条件がない
		  d_coupon.disp_flag = 1 AND -- カート等で表示するか
		  d_coupon.use_start_time >= '2019-01-01 00:00:00' AND
		    d_coupon.discount_type=2
--			(d_coupon.coupon_id = 'MjVhZTMwOGZjOWM2OTNlMDQzNzUyNmZlNTNh' OR
--			d_coupon.coupon_id = 'ODlmZDRlYWVmZWExZjIyY2M3MDRhMWQxNWRi')
		) as outer_d_coupon
	on
		d_coupon_target.coupon_id = outer_d_coupon.coupon_id
	cross join
	 	shopping.shp_d_calendar as d_calendar
	WHERE
	  	d_calendar.YMD_DATE between (outer_d_coupon.use_start_time - INTERVAL '2' DAY) and (outer_d_coupon.use_start_time + INTERVAL '2' DAY)
	) as base

INNER JOIN
	shopping.shp_r_item as r_item
ON
	LOWER(r_item.item_code) = LOWER(base.item_id)

LEFT OUTER JOIN
	(
	select
		inner_foi.order_date as order_date,
		inner_foi.store_id as store_id,
		inner_foi.item_id as item_id,
		sum(inner_foi.quantity) as quantity
	from
		shopping.shp_f_order_items as inner_foi
	group by
		inner_foi.order_date, inner_foi.store_id, inner_foi.item_id
	) as f_order_items
ON
	base.ymd_date = f_order_items.order_date AND
	r_item.store_id = f_order_items.store_id AND
	LOWER(r_item.item_code) = LOWER(f_order_items.item_id)

LEFT OUTER JOIN --ストアの変更履歴
    shopping.shp_d_store_history as d_store_hist
ON
	base.ymd_date = d_store_hist.store_date
	AND
    r_item.store_id = d_store_hist.store_account

WHERE
	r_item.delete_flag=0 AND
	r_item.display_flag=1 AND
	r_item.update_time < base.ymd_date -- 商品の更新日時が日付よりあとであること
) as T

LEFT OUTER JOIN
    shopping.shp_r_favorite_item_manage as out_wish
ON
    T.store_id = out_wish.store_id
    AND
    LOWER(T.item_id) = LOWER(out_wish.item_code)


GROUP BY
    T.ymd_date,
	T.day_of_week,
	-- ストア条件
	T.store_id,
	T.long_catalog_name,
	T.mrating_excellent,
	T.mrating_good,
	T.mrating_ok,
	T.mrating_bad,
	T.mrating_awful,
	T.best_store,
	T.store_introduction,
	T.store_category1,
	T.store_category2,
	T.store_category3,
	T.store_review_rate,
	T.pmall_status,
	-- 商品条件
	T.item_id,
	T.discount_rate,
	T.item_type,
    T.item_name,
    T.original_price, -- メーカー希望価格
    T.price, -- 通常価格
    T.headline,
    T.delivery_type,
    T.spec1,
    T.spec2,
    T.spec3,
    T.spec4,
    T.spec5,
    T.spec6,
    T.spec7,
    T.spec8,
    T.spec9,
    T.show_stock_type,
    T.final_pr_rate,
    T.brand_id,
    T.jan_code,
    T.y_shopping_display_flag,
    T.coupon_title,
	T.coupon_description,
    T.use_start_time,
    T.quantity
 ;