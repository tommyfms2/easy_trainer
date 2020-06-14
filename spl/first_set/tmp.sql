SELECT
--	count(*)
----環境
	f_order_items.order_date as ymd_date,
	d_calendar.DAY_OF_WEEK as day_of_week,
--ストア条件
    f_order_items.store_id as store_id,
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
--商品条件
    r_item.item_code as item_code,
    r_item.item_type as item_type,
    r_item.item_name as item_name,
    r_item.original_price as original_price, -- メーカー希望価格
    f_order_items.original_pricetax as original_pricetax, -- 税込み販売価格
    r_item.headline as headline,
    f_order_items.brand_code as brand_code,
    r_item.delivery_type as delivery_type,
    f_order_items.product_category as product_category_id,
    f_order_items.gpath1 as gpath1,
    f_order_items.gpath2 as gpath2,
    f_order_items.gpath3 as gpath3,
    f_order_items.gpath4 as gpath4,
    f_order_items.gpath5 as gpath5,
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
--    r_item_review.avg_review_score as avg_review_score,
--    r_item_review.review_num as review_num,
    wish.wish_count as wish_count,
--    quantity_tbl.d1_ago as d1_ago,
--    quantity_tbl.d2_ago as d2_ago,
--    quantity_tbl.d3_ago as d3_ago,
--    quantity_tbl.d4_ago as d4_ago,
--    quantity_tbl.d5_ago as d5_ago,
--    quantity_tbl.d6_ago as d6_ago,
--    quantity_tbl.d7_ago as d7_ago,
--    quantity_tbl.d8_ago as d8_ago,
--    quantity_tbl.d9_ago as d9_ago,
--    quantity_tbl.d10_ago as d10_ago,
--    quantity_tbl.d11_ago as d11_ago,
--    quantity_tbl.d12_ago as d12_ago,
--    quantity_tbl.d13_ago as d13_ago,
--    quantity_tbl.d14_ago as d14_ago,
    (cast(f_order_items.item_coupon_discount as float)/f_order_items.original_pricetax) as discount_rate, -- 割引率
    wish.quantity as quantity --正解データ

FROM
    shopping.shp_f_order_items as f_order_items
INNER JOIN
    shopping.shp_r_item as r_item
ON
    f_order_items.store_id = r_item.store_id
    AND
    f_order_items.item_id = r_item.item_code

--LEFT JOIN
----ストアIDと商品IDごとの、レビューの数・平均スコア
--    (
--    SELECT
--        out_f_order_items.order_date as order_date,
--        out_f_order_items.store_id as store_id,
--        out_f_order_items.item_id as item_id,
--        AVG(case when out_f_order_items.store_id=out_r_item_review.store_id and out_f_order_items.item_id=out_r_item_review.item_id and out_r_item_review.create_time < CAST(out_f_order_items.order_date as DATE FORMAT 'YYYYMMDD') and (out_r_item_review.delete_time is NULL or out_r_item_review.delete_time > CAST(out_f_order_items.order_date as DATE FORMAT 'YYYYMMDD')) then out_r_item_review.score else null end) as avg_review_score,
--        COUNT(case when out_f_order_items.store_id=out_r_item_review.store_id and out_f_order_items.item_id=out_r_item_review.item_id and out_r_item_review.create_time < CAST(out_f_order_items.order_date as DATE FORMAT 'YYYYMMDD') and (out_r_item_review.delete_time is NULL or out_r_item_review.delete_time > CAST(out_f_order_items.order_date as DATE FORMAT 'YYYYMMDD')) then out_r_item_review.item_id else null end) as review_num
--    FROM
--    (
--        SELECT
--            in_f_order_items.order_date as order_date,
--            in_f_order_items.store_id as store_id,
--            in_f_order_items.item_id as item_id
--        FROM
--            shopping.shp_f_order_items as in_f_order_items
--        WHERE
----        時期は絞る
--            in_f_order_items.order_date between '20190101' and '20200309'
--            AND
--            in_f_order_items.gpath1 = 13457 --ファッションカテゴリ
--        GROUP BY
--            in_f_order_items.order_date, in_f_order_items.store_id, in_f_order_items.item_id
--    ) as out_f_order_items
--    LEFT JOIN
--    (
--    	SELECT
--    		in_r_item_review.store_id as store_id, in_r_item_review.item_id as item_id, in_r_item_review.score as score, in_r_item_review.create_time, in_r_item_review.update_time, in_r_item_review.delete_time
--        FROM
--            shopping.shp_r_item_review as in_r_item_review
----        WHERE
----        で時間絞れる？
--    ) as out_r_item_review
--    ON
--    out_f_order_items.store_id = out_r_item_review.store_id
--    AND
--    out_f_order_items.item_id = out_r_item_review.item_id
--    GROUP BY
--    out_f_order_items.order_date, out_f_order_items.store_id, out_f_order_items.item_id
--    ) AS r_item_review
--ON
--    r_item.store_id = r_item_review.store_id
--    AND
--    r_item.item_code = r_item_review.item_id

LEFT JOIN
--ストアIDと商品IDごとの、お気に入りに入れられている数
    (
    SELECT
        out_f_order_items.order_date as order_date,
        out_f_order_items.store_id as store_id,
        out_f_order_items.item_id as item_id,
        avg(out_f_order_items.quantity) as quantity,
        count(case when out_f_order_items.store_id=out_wish.store_id and out_f_order_items.item_id=out_wish.item_code and out_wish.create_time < CAST(out_f_order_items.order_date as DATE FORMAT 'YYYYMMDD') and (out_wish.temp_delete_flag=0 or out_wish.temp_delete_time > CAST(out_f_order_items.order_date as DATE FORMAT 'YYYYMMDD')) then out_wish.item_code else null end) as wish_count
    FROM
    (
        SELECT
            in_f_order_items.order_date as order_date,
            in_f_order_items.store_id as store_id,
            in_f_order_items.item_id as item_id,
            SUM(in_f_order_items.quantity) as quantity
        FROM
            shopping.shp_f_order_items as in_f_order_items
        WHERE
--        時期は絞る
            in_f_order_items.order_date between '20190101' and '20200309'
            AND
            in_f_order_items.gpath1 = 13457 --ファッションカテゴリ縛り
            AND
            in_f_order_items.original_pricetax>0 --0円以上で販売されたもの
            AND
            in_f_order_items.quantity_decided > 0
            AND
            in_f_order_items.spcode=-1
            AND
            in_f_order_items.item_condition=0
            AND
            in_f_order_items.price_type=1 --通常販売価格でうれたもののみ、セールやプレミアム会員価格はなし
        GROUP BY
            in_f_order_items.order_date, in_f_order_items.store_id, in_f_order_items.item_id
    ) as out_f_order_items
    INNER JOIN
        shopping.shp_r_favorite_item_manage as out_wish
    ON
        out_f_order_items.store_id = out_wish.store_id
        AND
        out_f_order_items.item_id = out_wish.item_code
    GROUP BY
        out_f_order_items.order_date, out_f_order_items.store_id, out_f_order_items.item_id
    ) as wish
ON
    f_order_items.order_date = wish.order_date
    AND
    f_order_items.store_id = wish.store_id
    AND
    f_order_items.item_id = wish.item_id


--LEFT JOIN
----ストアIDと商品IDごとの、前2週間で売れた数
--	(
--	SELECT
--        out_f_order_items1.order_date as order_date,
--        out_f_order_items1.store_id as store_id,
--        out_f_order_items1.item_id as item_id,
--        AVG(out_f_order_items1.quantity) as quantity, -- ここが正解データとなるその日、そのストア、その商品の購入数
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-1 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d1_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-2 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d2_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-3 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d3_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-4 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d4_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-5 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d5_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-6 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d6_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-7 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d7_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-8 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d8_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-9 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d9_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-10 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d10_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-11 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d11_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-12 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d12_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-13 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d13_ago,
--        sum(case when out_f_order_items2.order_date=out_f_order_items1.order_date-14 and out_f_order_items1.store_id=out_f_order_items2.store_id and out_f_order_items1.item_id=out_f_order_items2.item_id then out_f_order_items2.quantity else 0 end) as d14_ago
--    FROM
--        (
--        SELECT
--            in_f_order_items.order_date as order_date,
--            in_f_order_items.store_id as store_id,
--            in_f_order_items.item_id as item_id,
--            sum(in_f_order_items.quantity) as quantity
--        FROM
--            shopping.shp_f_order_items as in_f_order_items
--        WHERE
----            in_f_order_items.store_id = 'moonstar'
----            AND
----            (in_f_order_items.item_id = '70571043' or in_f_order_items.item_id = '1121198')
----            AND
--            in_f_order_items.order_date between '20190101' and '20200309'
--            AND
--            in_f_order_items.gpath1 = 13457
--        GROUP BY
--            in_f_order_items.order_date, in_f_order_items.store_id, in_f_order_items.item_id
--        ) AS out_f_order_items1
--        LEFT JOIN
--        (
--        SELECT
--            in_f_order_items.order_date as order_date,
--            in_f_order_items.store_id as store_id,
--            in_f_order_items.item_id as item_id,
--            sum(in_f_order_items.quantity) as quantity
--        FROM
--            shopping.shp_f_order_items as in_f_order_items
--        WHERE
--            in_f_order_items.order_date between '20200210' and '20200226'
--            AND
--            in_f_order_items.gpath1 = 13457 --ファッションカテゴリ
--        GROUP BY
--            in_f_order_items.order_date, in_f_order_items.store_id, in_f_order_items.item_id
--        ) as out_f_order_items2
--        ON
--        out_f_order_items1.store_id = out_f_order_items2.store_id
--        AND
--        out_f_order_items1.item_id = out_f_order_items1.item_id
--        GROUP BY
--        out_f_order_items1.order_date, out_f_order_items1.store_id, out_f_order_items1.item_id
--	) AS quantity_tbl
--ON
--	r_item.store_id = f_order_items.store_id
--	AND
--	r_item.item_code = f_order_items.item_id

LEFT JOIN --ストアの変更履歴
    shopping.shp_d_store_history as d_store_hist
ON
	f_order_items.order_date = d_store_hist.store_date
	AND
    f_order_items.store_id = d_store_hist.store_account

--LEFT JOIN --商品が売れた数
--    (
--    SELECT
--        in_f_order_items.order_date as order_date,
--        in_f_order_items.store_id as store_id,
--        in_f_order_items.item_id as item_id,
--        SUM(in_f_order_items.quantity_decided) as quantity
--    FROM
--        shopping.shp_f_order_items as in_f_order_items
--    WHERE
--        in_f_order_items.order_date between '20190101' and '20200309'
--        AND
--        in_f_order_items.gpath1 = 13457 --ファッションカテゴリ縛り
--        AND
--        in_f_order_items.original_pricetax>0 --0円以上で販売されたもの
--        AND
--        in_f_order_items.quantity_decided > 0
--        AND
--        in_f_order_items.spcode=-1
--        AND
--        in_f_order_items.item_condition=0
--        AND
--        in_f_order_items.price_type=1 --通常販売価格でうれたもののみ、セールやプレミアム会員価格はなし
--    GROUP BY
--        in_f_order_items.order_date, in_f_order_items.store_id, in_f_order_items.item_id
--    ) as quantity_tbl
--ON
--    f_order_items.order_date = quantity_tbl.order_date
--    and
--    f_order_items.store_id = quantity_tbl.store_id
--    and
--    f_order_items.item_id = quantity_tbl.item_id

INNER JOIN --カレンダー
    shopping.shp_d_calendar as d_calendar
ON
    f_order_items.order_date = d_calendar.YMD_DATE

WHERE
--最終条件
    r_item.delete_flag=0
    AND
    r_item.create_time > '2019-01-01 00:00:00' --商品の特徴に学習の重点を置くため
    AND
    f_order_items.order_date between '20190101' and '20200309'
    AND
    f_order_items.gpath1 = 13457 --ファッションカテゴリ縛り
    AND
    f_order_items.original_pricetax>0 --0円以上で販売されたもの
    AND
    f_order_items.spcode=-1
    AND
    f_order_items.price_type=1 --通常販売価格でうれたもののみ、セールやプレミアム会員価格はなし
	AND
	f_order_items.item_tax_code=0
	AND
	f_order_items.item_condition=0

--	AND
--	f_order_items.store_id='eco-styles-honey'
--	and
--	f_order_items.item_id='eg8980'

	;