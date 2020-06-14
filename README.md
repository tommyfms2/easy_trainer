# scope-coupon-optimizer


### 手順
1. config_builder.pyで学習設定configを作成
2. configを調整
3. train.pyでconfigを指定し学習
4. predict.pyで予測
 　  
 　  


#### 1.config_builder.pyで学習設定configを作成

    $ python config_builder.py -c sample_config -i ./data/sample_traindata.csv -t sample_target
    

|Abbreviation|Parameter|Required or default|Desc|ex|
|:--|:--|:--|:--|:--|
|-c|--config_name|O|configsディレクトリ以下に作成されるフォルダ名．一つのデータについて一つのコンフィグファイルを作成する．|sample_config|
|-i|--input|O|dataディレクトリ以下の学習データを指定|./data/sample_traindata.csv|
|-t|--target_column|O|指定した学習データの正解データに当たるカラム名を指定する．|sample_target|
|-o|--output_dir_name|outputs|コンフィグディレクトリ以下にできる学習済みデータなどの出力先||
|-d|--delimiter|tab|'tab' or 'comma'||
|-b|--batch_size|8192|ハイパーパラメタ．バッチサイズ||
|-de|--dim_embed|64|ハイパーパラメタ．各カラムの入力を何次元のベクトルに変換するか||
|-dh|--dim_hidden|128|ハイパーパラメタ．隠れ層のニューロン数||
|-e|--epochs|10|学習ループ数||
||--force_rebuild||同名のコンフィグフォルダがあっても削除して再作成する||


configs配下に指定したconfig_nameが生成され，その配下にconf.ymlが生成される  
　　

#### conf.ymlを調整

|Key||Recommend Adjustment|Desc|
|:--|:--|:--|:--|
|input_file||X|学習データのパス|
|output_dir_name||O（上書きしたくないとき）|学習結果の保存フォルダ|
|delimiter||X|学習データの区切り文字|
|batch_size||O|ハイパーパラメタ|
|dim_embed||O|ハイパーパラメタ|
|dim_hidden||O|ハイパーパラメタ|
|epochs||O|反復学習数|
|target_columns||X|正解データのカラム|
|train_columns||O|この配下に学習データの各カラムの学習方法を指定する|
||name|X|カラム名|
||encoder_type|O|data, label_encoder, text_encoder, as_label のいずれかを指定|
||coeff|O|as_labelのとき指定|
||max_length|O|text_encoderのとき指定|

　  
encoder_typeについて  

|encoder_type|Required Config|Desc|
|:--|:--|:--|:--|
|label_encoder|なし|入力値が一対一に変換され，入力に用いられる．入力値自体の文字列に意味がないときに使用．例）暗号化されたユーザ名，カテゴリID|
|text_encoder|max_length|入力値自体に意味があるときに使用．max_lengthで最大文字列数を指定する．例）タイトル|
|as_label|coeff|整数の入力で，それ自体に意味があるときに用いる．例）価格，レビュー得点|

　  


#### 3. train.pyでconfigを指定し学習
    $ python train.py -c ./configs/sample_config/conf.yml
    
    ...
    Epoch 9/10
	1/1 [==============================] - 1s 592ms/step - loss: 2363.8345 - mae: 39.8410 - mse: 2363.8345 - val_loss: 0.0000e+00 - val_mae: 0.0000e+00 - val_mse: 0.0000e+00
	Epoch 10/10
	1/1 [==============================] - ETA: 0s - loss: 2171.1631 - mae: 38.3303 - mse: 2171.1631
	Epoch 00010: val_loss did not improve from 0.00000
	1/1 [==============================] - 1s 569ms/step - loss: 2171.1631 - mae: 38.3303 - mse: 2171.1631 - val_loss: 0.0000e+00 - val_mae: 0.0000e+00 - val_mse: 0.0000e+00
	saving weights
	saved result file.
	
	Process finished with exit code 0
	

|Abbreviation|Parameter|Requirement|Desc|ex|
|:--|:--|:--|:--|:--|:--|
|-c|--config|O|設定した conf.ymlを指定| ./configs/sample_config/conf.yml
||--test|X|指定すると最初の1000行のみを使って学習する| --test|



　　　
　　　

#### 4. predict.pyで予測
    $ python predict.py -i ./data/sample_preddata.csv -c ./configs/sample_config/outputs/conf.yml
    
 
outputs配下にpred_results.csvが作成され，その中に正解データと予測結果が保存される．
    



