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
    wish.wish_count as wish_count,
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


LEFT OUTER JOIN
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


LEFT OUTER JOIN --ストアの変更履歴
    shopping.shp_d_store_history as d_store_hist
ON
	f_order_items.order_date = d_store_hist.store_date
	AND
    f_order_items.store_id = d_store_hist.store_account

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

	;